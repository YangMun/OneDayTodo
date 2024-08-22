import SwiftUI

struct CategoryManagerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @FetchRequest(entity: Category.entity(), sortDescriptors: []) private var categories: FetchedResults<Category>
    @State private var isPresentingAddCategory = false

    var body: some View {
        VStack {
            // Custom Navigation Bar
            HStack {
                Button(action: {
                    dismissView()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }

                Spacer()

                Text("카테고리")
                    .font(.headline)
                    .foregroundColor(.black)

                Spacer()

                Button(action: {
                    isPresentingAddCategory = true
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(Color.white)

            // Grouping title
            HStack {
                Text("일반")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.leading, 16)
                Spacer()
            }

            // Category List
            FlowLayout(categories: categories) { category in
                Button(action: {
                    navigateToEditCategory(category)
                }) {
                    Text(category.title ?? "카테고리")
                        .foregroundColor(.black)
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                }
                .padding(.horizontal, 4)
            }
            .padding(.top, 8)

            Spacer()
        }
        .background(Color.white)
        .navigationBarHidden(true)
        .sheet(isPresented: $isPresentingAddCategory) {
            AddCategoryModalView(isPresented: $isPresentingAddCategory)
                .presentationDetents([.medium])
                .environment(\.managedObjectContext, viewContext)
        }
    }

    private func dismissView() {
        presentationMode.wrappedValue.dismiss()
    }

    private func navigateToEditCategory(_ category: Category) {
        let editCategoryView = EditCategoryView(category: category)
        let editCategoryViewController = UIHostingController(rootView: editCategoryView.environment(\.managedObjectContext, viewContext))
        editCategoryViewController.modalPresentationStyle = .fullScreen
        
        UIApplication.shared.windows.first?.rootViewController?.present(editCategoryViewController, animated: true, completion: nil)
    }
}

struct EditCategoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var category: Category
    @State private var categoryName: String = ""

    var body: some View {
        VStack {
            // Custom Navigation Bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.black)
                }

                Spacer()

                Text("카테고리")
                    .font(.headline)
                    .foregroundColor(.black)

                Spacer()

                Button(action: {
                    saveCategory()
                }) {
                    Text("완료")
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color.white)

            // Category Name TextField
            TextField("카테고리 이름", text: $categoryName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 20)

            // Delete Button placed directly below the TextField with top padding
            Button(action: {
                deleteCategory()
            }) {
                Text("삭제하기")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(10)
                    .padding(.top, 20) // Adjust padding as needed
            }

            Spacer()
        }
        .onAppear {
            categoryName = category.title ?? ""
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
    }

    private func saveCategory() {
        category.title = categoryName
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("카테고리 저장 실패: \(error.localizedDescription)")
        }
    }

    private func deleteCategory() {
        viewContext.delete(category)
        do {
            try viewContext.save()
            presentationMode.wrappedValue.dismiss()
        } catch {
            print("카테고리 삭제 실패: \(error.localizedDescription)")
        }
    }
}

struct AddCategoryModalView: View {
    @Binding var isPresented: Bool
    @Environment(\.managedObjectContext) private var viewContext
    @State private var categoryName: String = ""

    var body: some View {
        VStack {
            // Handle
            Rectangle()
                .frame(width: 40, height: 5)
                .foregroundColor(Color.gray.opacity(0.5))
                .cornerRadius(2.5)
                .padding(.top, 8)

            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Text("취소")
                        .foregroundColor(.red)
                }
                Spacer()
                Text("카테고리 추가")
                    .font(.headline)
                    .foregroundColor(.black)
                Spacer()
                Button(action: {
                    addCategory()
                    isPresented = false
                }) {
                    Text("확인")
                        .foregroundColor(.blue)
                }
            }
            .padding()

            TextField("카테고리 이름", text: $categoryName)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.top, 20)

            Spacer()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
    }

    private func addCategory() {
        let newCategory = Category(context: viewContext)
        newCategory.title = categoryName

        do {
            try viewContext.save()
        } catch {
            print("카테고리 저장 실패: \(error.localizedDescription)")
        }
    }
}

struct FlowLayout<Data: RandomAccessCollection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let content: (Data.Element) -> Content

    @State private var totalHeight = CGFloat.infinity

    init(categories: Data, @ViewBuilder content: @escaping (Data.Element) -> Content) {
        self.data = categories
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            self.generateContent(in: geometry)
        }
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: .topLeading) {
            ForEach(self.data, id: \.self) { item in
                self.content(item)
                    .padding([.horizontal, .vertical], 4)
                    .alignmentGuide(.leading, computeValue: { d in
                        if (abs(width - d.width) > geometry.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == self.data.last! {
                            width = 0 // last item
                        } else {
                            width -= d.width
                        }
                        return result
                    })
                    .alignmentGuide(.top, computeValue: { d in
                        let result = height
                        if item == self.data.last! {
                            height = 0 // last item
                        }
                        return result
                    })
            }
        }
        .background(viewHeightReader($totalHeight))
    }

    private func viewHeightReader(_ binding: Binding<CGFloat>) -> some View {
        return GeometryReader { geo -> Color in
            DispatchQueue.main.async {
                binding.wrappedValue = geo.size.height
            }
            return Color.clear
        }
    }
}

struct CategoryManagerView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext

        // 미리보기를 위한 가상의 카테고리 생성
        let mockCategory = Category(context: context)
        mockCategory.title = "카테고리"

        return CategoryManagerView()
            .environment(\.managedObjectContext, context)
    }
}
