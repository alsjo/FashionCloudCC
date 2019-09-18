//
//  ViewController.swift
//  FashionCloudCC
//
//  Created by vitalii on 9/18/19.
//  Copyright © 2019 Vitalii. All rights reserved.
//

import UIKit

//   let article = try Article(json)

//
// To read values from URLs:
//
//   let task = URLSession.shared.articleElementTask(with: url) { articleElement, response, error in
//     if let articleElement = articleElement {
//       ...
//     }
//   }
//   task.resume()

// MARK: - ArticleElement
struct ArticleElement: Codable {
    let uuid: String
    let sortingOrder: Int
    let name: String
    let tags: [String]
    
    enum CodingKeys: String, CodingKey {
        case uuid
        case sortingOrder = "sorting_order"
        case name, tags
    }
}



class ArticlesModel:NSObject
{
    var numberOfArticles: Int!
    var Articles: [ArticleElement]!
    init(Articles: [ArticleElement])
    {
        super.init()
        self.Articles = self.sortedArticles(articles: Articles);
        self.numberOfArticles = Articles.count;
    }
    
    func sortedArticles(articles: [ArticleElement]) -> [ArticleElement]
    {
        guard articles.count > 1 else {
           return articles;
        }
        //mutated copy
        var output: Array<ArticleElement> = articles
        
        for primaryIndex in 0..<articles.count {
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
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var lbMessage: UILabel!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var ArticlesTableView: UITableView!
    private let refreshControl = UIRefreshControl()

    var Articles: ArticlesModel?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        // Add Refresh Control to Table View
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if #available(iOS 10.0, *) {
            self.ArticlesTableView.refreshControl = refreshControl
        } else {
            self.ArticlesTableView.addSubview(refreshControl)
        }
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        refreshControl.tintColor = UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)
        refreshControl.attributedTitle = NSAttributedString(string: "Fetching Articles ...",
                                                            attributes: [NSAttributedString.Key.foregroundColor : UIColor(red:0.25, green:0.72, blue:0.85, alpha:1.0)])
        
        self.getArticles { (articles, error) in
            if(articles == nil)
            {
                print("Unexpected error: \(error?.localizedDescription).")
            }
            else
            {
                // let article = try Article(ArticlesJson)
                self.Articles = ArticlesModel(Articles: articles!)
                DispatchQueue.main.async {
                    self.ArticlesTableView.reloadData()
                }
            }
        }
    }
    
    @objc func refreshData(_ sender: Any) {
        self.activityIndicatorView.isHidden = false;
        self.activityIndicatorView.startAnimating()
        self.getArticles { (articles, error) in
            if(articles == nil)
            {
                print("Unexpected error: \(error?.localizedDescription).")
                DispatchQueue.main.async {
                    self.stopIndicators()
                }
            }
            else
            {
                // let article = try Article(ArticlesJson)
                self.Articles = ArticlesModel(Articles: articles!)
                DispatchQueue.main.async {
                    self.ArticlesTableView.reloadData()
                    self.stopIndicators()
                }
            }
        }
    }

    func stopIndicators()
    {
        self.refreshControl.endRefreshing()
        self.activityIndicatorView.stopAnimating()
        self.activityIndicatorView.isHidden = true;
    }
    
    func getArticles(_ completion: @escaping (Article?, Error?)->())
    {
        let url:URL = URL(string: "http://challenge.fashionexchange.nl:80/api/articles/")!

        let task = URLSession.shared.articleTask(with: url) { articleElement, response, error in
            if let articleElement = articleElement
            {
               completion(articleElement, nil)
            }
            else
            {
                completion(nil, error)
            }
            
        }
        task.resume()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if(self.Articles == nil)
        {
            self.lbMessage.isHidden = false;
        }
        else
        {
             self.lbMessage.isHidden = true;
        }
        return self.Articles == nil ? 0 : Articles!.numberOfArticles;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath)
        let text = self.Articles!.Articles[indexPath.row].name;
        cell.textLabel?.text = text;
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

    let tagsSegueIdentifier = "ShowTagsSegue"
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == tagsSegueIdentifier,
            let destination = segue.destination as? TagsViewController,
            let articleIndex = self.ArticlesTableView.indexPathForSelectedRow?.row
        {
             let article = self.Articles!.Articles[articleIndex]
            destination.article = article
        }
    }
}

// MARK: ArticleElement convenience initializers and mutators

extension ArticleElement {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(ArticleElement.self, from: data)
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
        sortingOrder: Int? = nil,
        name: String? = nil,
        tags: [String]? = nil
        ) -> ArticleElement {
        return ArticleElement(
            uuid: uuid ?? self.uuid,
            sortingOrder: sortingOrder ?? self.sortingOrder,
            name: name ?? self.name,
            tags: tags ?? self.tags
        )
    }
    
    func jsonData() throws -> Data {
        return try newJSONEncoder().encode(self)
    }
    
    func jsonString(encoding: String.Encoding = .utf8) throws -> String? {
        return String(data: try self.jsonData(), encoding: encoding)
    }
}

typealias Article = [ArticleElement]

extension Array where Element == Article.Element {
    init(data: Data) throws {
        self = try newJSONDecoder().decode(Article.self, from: data)
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

// MARK: - Helper functions for creating encoders and decoders

func newJSONDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        decoder.dateDecodingStrategy = .iso8601
    }
    return decoder
}

func newJSONEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    if #available(iOS 10.0, OSX 10.12, tvOS 10.0, watchOS 3.0, *) {
        encoder.dateEncodingStrategy = .iso8601
    }
    return encoder
}

// MARK: - URLSession response handlers

extension URLSession {
    fileprivate func codableTask<T: Codable>(with url: URL, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completionHandler(nil, response, error)
                return
            }
            completionHandler(try? newJSONDecoder().decode(T.self, from: data), response, nil)
        }
    }
    
    func articleTask(with url: URL, completionHandler: @escaping (Article?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        return self.codableTask(with: url, completionHandler: completionHandler)
    }
    
   
}






