# Slider M2

Slider Extension for Magento 2.x

## Installation (this fork)

in `magento_project_dir/app/code/SY/Slider`

`git clone git@github.com:MattrCoUk/Slider-M2.git .`


(or simply download and unzip the repo)


`bin/magento module:enable SY_Slider`

`bin/magento setup:upgrade`

`bin/magento cache:flush`



### With Composer

in `magento_project_dir`


`composer config repositories.sy-slider vcs git@github.com:MattrCoUk/Slider-M2.git`

`composer require sy/slider`

`bin/magento module:enable SY_Slider`

`bin/magento setup:upgrade`

`bin/magento cache:flush`


## Uninstallation

in `magento_project_dir`

`bin/magento module:disable SY_Slider`

`rm -rf app/code/SY/Slider`


Drop `sy_slider` table in database if you're planning to reinstall the SY_Slider as it might cause problems.


`bin/magento setup:upgrade`

`bin/magento cache:flush`



### With Composer

`bin/magento module:disable SY_Slider`

`composer remove sy/slider`


Drop `sy_slider` table in database if you're planning to reinstall the SY_Slider as it might cause problems.


`bin/magento setup:upgrade`

`bin/magento cache:flush`


## More info


[GUIDE](https://github.com/SlavaYurthev/Slider-M2/wiki)
