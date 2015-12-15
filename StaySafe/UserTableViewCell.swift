//
//  UserTableViewCell.swift
//  StaySafe
//
//  Created by Luke Madronal on 12/15/15.
//  Copyright © 2015 Luke Madronal. All rights reserved.
//

import UIKit

class UserTableViewCell: UITableViewCell {
    
    @IBOutlet var profPicThumbnail: UIImageView!
    @IBOutlet var nameLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
