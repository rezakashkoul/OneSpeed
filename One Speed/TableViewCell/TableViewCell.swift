//
//  TableViewCell.swift
//  One Speed
//
//  Created by Reza Kashkoul on 19/5/1401 AP.
//

import UIKit

class TableViewCell: UITableViewCell {

    @IBOutlet weak var downloadLabel: UILabel!
    @IBOutlet weak var uploadLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

    }
    
    func setupCell(download: String, upload: String) {
        downloadLabel.text = download
        uploadLabel.text = upload
    }
}
