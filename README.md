# IGListKit + PinLayout 使用筆記

> 使用 IGListKit 建立高效多版位列表，Cell 內用 PinLayout 排版。

---

## 何時適合用 IGListKit？

- **適合**
  - 社群動態牆 / 新聞 Feed / 首頁探索頁
  - 一個畫面有很多不同區塊（Banner、橫向列表、Grid、廣告…）
  - 資料會頻繁插入、刪除、排序、重新整理

---

## 架構概念

- **Model**：純資料結構 (`Photo`, `Article`…)
- **Section Model (`ListDiffable`)**：給 IGListKit 用來做 diff 的包裝
- **SectionController (`ListSectionController`)**：決定一個區塊的 items、大小、Cell
- **Cell**：用 PinLayout（或 FlexLayout）在 `layoutSubviews()` 排版

---

## 安裝（概念）

- 透過 Swift Package Manager / Cocoapods 引入：
  - `IGListKit`
  - `PinLayout`（可選）
- 在需要的檔案中匯入：

import IGListKit
import PinLayout---

## 1. 資料 Model

struct Photo {
    let id: Int
    let title: String
    let imageURL: URL
}---

## 2. Section Model（實作 `ListDiffable`）

import IGListKit

final class PhotosSectionModel: ListDiffable {
    let photos: [Photo]

    init(photos: [Photo]) {
        self.photos = photos
    }

    func diffIdentifier() -> NSObjectProtocol {
        "photos-section" as NSString
    }

    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let other = object as? PhotosSectionModel else { return false }
        return photos == other.photos
    }
}---

## 3. ViewModel（負責取資料 + 組 SectionModel）

import Combine

protocol PhotoServiceProtocol {
    func fetchPhotos() -> AnyPublisher<[Photo], Error>
}

final class PhotosViewModel: ObservableObject {
    @Published var sectionModel: PhotosSectionModel?
    @Published var isLoading = false
    @Published var error: Error?

    private let service: PhotoServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    init(service: PhotoServiceProtocol) {
        self.service = service
    }

    func load() {
        isLoading = true
        error = nil

        service.fetchPhotos()
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let err) = completion {
                        self?.error = err
                    }
                },
                receiveValue: { [weak self] photos in
                    self?.sectionModel = PhotosSectionModel(photos: photos)
                }
            )
            .store(in: &cancellables)
    }
}---

## 4. Cell：用 PinLayout 排版

import UIKit
import PinLayout

final class PhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        titleLabel.font = .systemFont(ofSize: 11)
        titleLabel.textColor = .white
        titleLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.pin.all()
        titleLabel.pin.horizontally().bottom().height(20)
    }

    func configure(with photo: Photo) {
        titleLabel.text = photo.title
        // 在這裡載入圖片（例如 SDWebImage）
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
    }
}> 建議：**所有 frame / layout 放在 `layoutSubviews()`，不要在 init 裡寫死。**

---

## 5. SectionController

import IGListKit

final class PhotoSectionController: ListSectionController {
    private var model: PhotosSectionModel?

    override init() {
        super.init()
        minimumLineSpacing = 2
        minimumInteritemSpacing = 2
        inset = .zero
    }

    override func numberOfItems() -> Int {
        model?.photos.count ?? 0
    }

    override func sizeForItem(at index: Int) -> CGSize {
        guard let context = collectionContext else { return .zero }
        let width = context.containerSize.width
        let spacing: CGFloat = 2
        let totalSpacing = spacing * 2
        let itemWidth = floor((width - totalSpacing) / 3)
        return CGSize(width: itemWidth, height: itemWidth)
    }

    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard
            let cell = collectionContext?.dequeueReusableCell(
                of: PhotoCell.self,
                for: self,
                at: index
            ) as? PhotoCell,
            let photo = model?.photos[index]
        else {
            return UICollectionViewCell()
        }

        cell.configure(with: photo)
        return cell
    }

    override func didUpdate(to object: Any) {
        model = object as? PhotosSectionModel
    }
}---

## 6. ViewController + ListAdapter

import UIKit
import IGListKit
import Combine

final class PhotosViewController: UIViewController {
    private lazy var adapter = ListAdapter(
        updater: ListAdapterUpdater(),
        viewController: self
    )

    private let collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: UICollectionViewFlowLayout()
    )

    private let viewModel: PhotosViewModel
    private var cancellables = Set<AnyCancellable>()

    init(viewModel: PhotosViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        adapter.collectionView = collectionView
        adapter.dataSource = self

        bindViewModel()
        viewModel.load()
    }

    private func bindViewModel() {
        viewModel.$sectionModel
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.adapter.performUpdates(animated: true)
            }
            .store(in: &cancellables)
    }
}

extension PhotosViewController: ListAdapterDataSource {
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        guard let sectionModel = viewModel.sectionModel else { return [] }
        return [sectionModel]
    }

    func listAdapter(_ listAdapter: ListAdapter,
                     sectionControllerFor object: Any) -> ListSectionController {
        PhotoSectionController()
    }

    func emptyView(for listAdapter: ListAdapter) -> UIView? { nil }
}---

## 常見擴充方式

- **多種版位**
  - 多個 `XXXSectionModel` + `XXXSectionController` + 不同 Cell。
  - ViewModel 準備 `[ListDiffable]`，依順序代表畫面區塊。

- **資料更新**
  - ViewModel 改變 Published（例如新增/刪除/排序），呼叫 `performUpdates` 即可。
  - 不需要手動算 indexPath / `insertItems` / `deleteItems`。
