//
//  TagsViewController.swift
//  FashionCloudCC
//
//  Created by vitalii on 9/18/19.
//  Copyright © 2019 Vitalii. All rights reserved.
//

import UIKit

//   let mappingSet = try MappingSet(json)

//
// To read values from URLs:
//
//   let task = URLSession.shared.mappingSetElementTask(with: url) { mappingSetElement, response, error in
//     if let mappingSetElement = mappingSetElement {
//       ...
//     }
//   }
//   task.resume()

// MARK: - MappingSetElement
struct MappingSetElement: Codable {
    let uuid, name: String
}


//   let mapping = try Mapping(json)

//
// To read values from URLs:
//
//   let task = URLSession.shared.mappingElementTask(with: url) { mappingElement, response, error in
//     if let mappingElement = mappingElement {
//       ...
//     }
//   }
//   task.resume()

// MARK: - MappingElement
struct MappingElement: Codable {
    let uuid: String
    let sortingOrder: Double
    let sourceTags, destinationValue: String
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case sortingOrder = "sorting_order"
        case sourceTags = "source_tags"
        case destinationValue = "destination_value"
    }
}

class TagsModel: NSObject
{
    var numberOfTags: Int
    var Tags: [String]
    var redIndexes: [Int]
    init(Tags: [String], redIndexes: [Int])
    {
        self.Tags = Tags;
        self.numberOfTags = Tags.count;
        self.redIndexes = redIndexes
    }
    
    
}

enum TagType {
    // enumeration definition goes here
    case original, shop_floor, back_office
}

class TagsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var scTagType: UISegmentedControl!
    @IBOutlet weak var TagsTableView: UITableView!
    
    @IBOutlet weak var lbMessage: UILabel!
    private let refreshControl = UIRefreshControl()
    
    var mappingSet: [MappingSetElement]?

    var Tags: TagsModel?
    var article: ArticleElement!
   
    var mappingOriginal: [MappingElement]?
    var mappingShopFloor: [MappingElement]?
    var mappingBackOffice: [MappingElement]?
    
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 10.0, *) {
            self.TagsTableView.refreshControl = refreshControl
        } else {
            self.TagsTableView.addSubview(refreshControl)
        }
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Tags ...",
                                                            attributes: [NSAttributedString.Key.foregroundColor : UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)])
        self.navigationItem.title = article.name
        self.getMappingSet { (mappingSet, error) in
            if(mappingSet == nil)
            {
                print("Unexpected error")
            }
            else
            {
                // let article = try Article(ArticlesJson)
                self.mappingSet = MappingSet(mappingSet!)
                DispatchQueue.main.async {
                    self.scTagType.setTitle(self.mappingSet![0].name, forSegmentAt: 0)
                    self.scTagType.setTitle(self.mappingSet![1].name, forSegmentAt: 1)
                    self.scTagType.setTitle(self.mappingSet![2].name, forSegmentAt: 2)
                }
                self.getMapping(param: (self.mappingSet![0] as MappingSetElement).uuid, completion: { (mapping, error) in
                    if(mapping == nil)
                    {
                        print("Unexpected error")
                    }
                    else
                    {
                        self.mappingOriginal = self.sortedMapping(mapping: mapping!)
                        self.Tags = self.getTags(article: self.article, type: .original)
                        DispatchQueue.main.async {
                            self.TagsTableView.reloadData()
                        }
                    }
                })
                self.getMapping(param: (self.mappingSet![1] as MappingSetElement).uuid, completion: { (mapping, error) in
                    if(mapping == nil)
                    {
                        print("Unexpected error")
                    }
                    else
                    {
                        self.mappingShopFloor = self.sortedMapping(mapping: mapping!)
                    }
                })
                self.getMapping(param: (self.mappingSet![2] as MappingSetElement).uuid, completion: { (mapping, error) in
                    if(mapping == nil)
                    {
                        print("Unexpected error")
                    }
                    else
                    {
                        self.mappingBackOffice = self.sortedMapping(mapping: mapping!)
                    }
                })
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func stopIndicators()
    {
        self.refreshControl.endRefreshing()
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.isHidden = true;
    }
    
    @objc func refreshData(_ sender: Any) {
        self.activityIndicatorView.isHidden = false;
        self.activityIndicatorView.startAnimating()
        let scIndex = self.scTagType.selectedSegmentIndex
        self.getMappingSet { (mappingSet, error) in
            if(mappingSet == nil)
            {
                print("Unexpected error")
                DispatchQueue.main.async {
                    self.stopIndicators()
                }
            }
            else
            {
                // let article = try Article(ArticlesJson)
                self.mappingSet = MappingSet(mappingSet!)
                DispatchQueue.main.async {
                    self.scTagType.setTitle(self.mappingSet![0].name, forSegmentAt: 0)
                    self.scTagType.setTitle(self.mappingSet![1].name, forSegmentAt: 1)
                    self.scTagType.setTitle(self.mappingSet![2].name, forSegmentAt: 2)
                }
                
                switch scIndex
                {
                case 0:
                    self.getMapping(param: (self.mappingSet![0] as MappingSetElement).uuid, completion: { (mapping, error) in
                        if(mapping == nil)
                        {
                            print("Unexpected error")
                            DispatchQueue.main.async {
                                self.stopIndicators()
                            }
                        }
                        else
                        {
                            self.mappingOriginal = self.sortedMapping(mapping: mapping!)
                            self.Tags = self.getTags(article: self.article, type: .original)
                            DispatchQueue.main.async {
                            self.TagsTableView.reloadData()
                               self.stopIndicators()
                            }
                        }
                    })
                case 1:
                    self.getMapping(param: (self.mappingSet![1] as MappingSetElement).uuid, completion: { (mapping, error) in
                        if(mapping == nil)
                        {
                            print("Unexpected error")
                            DispatchQueue.main.async {
                                self.stopIndicators()
                            }
                        }
                        else
                        {
                            self.mappingShopFloor = self.sortedMapping(mapping: mapping!)
                            self.Tags = self.getTags(article: self.article, type: .shop_floor)
                            DispatchQueue.main.async {
                                self.TagsTableView.reloadData()
                                self.stopIndicators()
                            }
                        }
                    })
                case 2:
                    self.getMapping(param: (self.mappingSet![2] as MappingSetElement).uuid, completion: { (mapping, error) in
                        if(mapping == nil)
                        {
                            print("Unexpected error")
                            DispatchQueue.main.async {
                                self.stopIndicators()
                            }
                        }
                        else
                        {
                            self.mappingBackOffice = self.sortedMapping(mapping: mapping!)
                            self.Tags = self.getTags(article: self.article, type: .back_office)
                            DispatchQueue.main.async {
                                self.TagsTableView.reloadData()
                                self.stopIndicators()
                            }
                        }
                    })
                default:
                    break;
                }
            }
        }
    }

    
    func getMappingSet(_ completion: @escaping (MappingSet?, Error?)->())
    {
        let url:URL = URL(string: "http://challenge.fashionexchange.nl:80/api/mappingsets/")!
        let task = URLSession.shared.mappingSetTask(with: url) { mappingSetElement, response, error in
            if let mappingSetElement = mappingSetElement {
                
                    completion(mappingSetElement, nil)
                }
                else
                {
                    completion(nil, error)
                }
                
            }
            task.resume()
    }
    
    func getMapping(param: String, completion: @escaping (Mapping?, Error?)->())
    {
        let url:URL = URL(string: "http://challenge.fashionexchange.nl:80/api/mappingsets/\(param)/mappings/")!
        let task = URLSession.shared.mappingTask(with: url) { mappingElement, response, error in
            if let mappingElement = mappingElement {
                
                completion(mappingElement, nil)
            }
            else
            {
                completion(nil, error)
            }
            
        }
        task.resume()
    }
    
    
    func sortedMapping(mapping: [MappingElement]) -> [MappingElement]
    {
        guard mapping.count > 1 else {
            return mapping;
        }
        //mutated copy
        var output: Array<MappingElement> = mapping
        
        for primaryIndex in 0..<mapping.count {
            let passes = (output.count - 1) - primaryIndex
            
            //"half-open" range operator
            for secondaryIndex in 0..<passes {
                let key = output[secondaryIndex].sortingOrder
                
                //compare / swap positions
                if (key > output[secondaryIndex + 1].sortingOrder) {
                    output.swapAt(secondaryIndex, secondaryIndex + 1)
                }
            }
        }
        
        return output
        
    }
    func updateHint()
    {
        if(self.Tags == nil || self.Tags?.Tags.isEmpty == true)
        {
            self.lbMessage.isHidden = false;
        }
        else
        {
        self.lbMessage.isHidden = true;
        }
    }
    
    func getTags(article: ArticleElement, type: TagType) -> TagsModel
    {
       // let sometype = TagType.original
        var tags:[String] = []
        var notFoundIndexes:[Int] = []
        var redIndexes:[Int] = []
        switch type
        {
        case .original:
            print("original")
            if (self.mappingOriginal == nil)
            {
                return TagsModel(Tags: [], redIndexes: []);
            }
            for i in 0...article.tags.count-1 {
                var mappingFound = false
                let tag = article.tags[i]
                for j in 0...self.mappingOriginal!.count-1
                {
                    let mappingString = self.mappingOriginal![j].sourceTags
                    if mappingString.contains(tag) {
                        mappingFound = true
                        tags.append(self.mappingOriginal![j].destinationValue)
                    }
                }
                if(mappingFound == false)
                {
                   // tags.append(tag)
                    notFoundIndexes.append(i)
                }
            }
            for i in 0..<notFoundIndexes.count
            {
                redIndexes.append(tags.uniques.count)
                tags.append(article.tags[notFoundIndexes[i]])
            }
        case .shop_floor:
             print("shop_floor")
             if (self.mappingShopFloor == nil)
             {
                return TagsModel(Tags: [], redIndexes: []);
             }
             for i in 0...article.tags.count-1 {
                var mappingFound = false
                let tag = article.tags[i]
                for j in 0...self.mappingShopFloor!.count-1
                {
                    let mappingString = self.mappingShopFloor![j].sourceTags
                    if mappingString.contains(tag) {
                        mappingFound = true
                        tags.append(self.mappingShopFloor![j].destinationValue)
                    }
                }
                if(mappingFound == false)
                {
                  //  tags.append(tag)
                    notFoundIndexes.append(i)
                }
            }
            for i in 0..<notFoundIndexes.count
            {
                redIndexes.append(tags.uniques.count)
                tags.append(article.tags[notFoundIndexes[i]])
            }
        case .back_office:
            print("back_office")
            if (self.mappingBackOffice == nil)
            {
                return TagsModel(Tags: [], redIndexes: []);
            }
            for i in 0...article.tags.count-1 {
                var mappingFound = false
                let tag = article.tags[i]
                for j in 0...self.mappingBackOffice!.count-1
                {
                    let mappingString = self.mappingBackOffice![j].sourceTags
                    if mappingString.contains(tag) {
                        mappingFound = true
                        tags.append(self.mappingBackOffice![j].destinationValue)
                    }
                }
                if(mappingFound == false)
                {
                   // tags.append(tag)
                    notFoundIndexes.append(i)
                }
            }
            for i in 0..<notFoundIndexes.count
            {
                redIndexes.append(tags.uniques.count)
                tags.append(article.tags[notFoundIndexes[i]])
                
            }
        }
        
        
       // let uniqueTags = Array(Set(tags))
        return TagsModel(Tags: tags.uniques, redIndexes: redIndexes);
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.updateHint()
        return self.Tags == nil ? 0 : self.Tags!.numberOfTags;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath)
        let text = self.Tags!.Tags[indexPath.row];
        cell.textLabel?.text = text;
         cell.textLabel?.textColor = UIColor.black
        if self.Tags!.redIndexes.contains(indexPath.row)
        {
            cell.textLabel?.textColor = UIColor.red
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    @IBAction func scTagsValueChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex
        {
        case 0:
            self.Tags = self.getTags(article: self.article, type: .original)
            self.TagsTableView.reloadData()
        case 1:
            self.Tags = self.getTags(article: self.article, type: .shop_floor)
            self.TagsTableView.reloadData()
        case 2:
            self.Tags = self.getTags(article: self.article, type: .back_office)
            self.TagsTableView.reloadData()
        default:
            break;
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}



// MARK: MappingSetElement convenience initializers and mutators

extension MappingSetElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MappingSetElement.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        uuid: String? = nil,
        name: String? = nil
        ) -> MappingSetElement {
        return MappingSetElement(
            uuid: uuid ?? self.uuid,
            name: name ?? self.name
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

typealias MappingSet = [MappingSetElement]

extension Array where Element == MappingSet.Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MappingSet.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

// MARK: MappingElement convenience initializers and mutators

extension MappingElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(MappingElement.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func with(
        uuid: String? = nil,
        sortingOrder: Double? = nil,
        sourceTags: String? = nil,
        destinationValue: String? = nil
        ) -> MappingElement {
        return MappingElement(
            uuid: uuid ?? self.uuid,
            sortingOrder: sortingOrder ?? self.sortingOrder,
            sourceTags: sourceTags ?? self.sourceTags,
            destinationValue: destinationValue ?? self.destinationValue
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

typealias Mapping = [MappingElement]

extension Array where Element == Mapping.Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Mapping.self, from: data)
    }
    
    init(_ json: String, using encoding: String.Encoding = .utf8) throws {
        guard let data = json.data(using: encoding) else {
            throw NSError(domain: "JSONDecoding", code: 0, userInfo: nil)
        }
        try self.init(data: data)
    }
    
    init(fromURL url: URL) throws {
        try self.init(data: try Data(contentsOf: url))
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}




// MARK: - URLSession response handlers

extension URLSession {
    fileprivate func codableTask<T: Codable>(with url: URL, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, response, error)
                return
            }
            if let response = response as? HTTPURLResponse {
                switch response.statusCode {
                case 500...599:
                    let ErrorResponseString = String(data: data, encoding: .utf8)
                    print("Network Error: \(ErrorResponseString ?? "unknown")")
                default:
                    break
                }
            }
            completionHandler(try? newJSONDecoder().decode(T.self, from: data), response, nil)
        }
    }
    
 
    func mappingSetTask(with url: URL, completionHandler: @escaping (MappingSet?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.codableTask(with: url, completionHandler: completionHandler)
    }
    
    func mappingTask(with url: URL, completionHandler: @escaping (Mapping?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.codableTask(with: url, completionHandler: completionHandler)
    }
}


extension Array where Element: Hashable {
    var uniques: Array {
        var buffer = Array()
        var added = Set<Element>()
        for elem in self {
            if !added.contains(elem) {
                buffer.append(elem)
                added.insert(elem)
            }
        }
        return buffer
    }
}
