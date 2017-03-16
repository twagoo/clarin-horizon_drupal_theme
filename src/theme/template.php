<?php
/**
 * @file
 * The primary PHP file for this theme.
 */

/**
 * Overrides theme_preprocess_html().
 */
function CLARIN_Horizon_preprocess_html(&$vars) {
  $fontCssLinkSourceSansPro = array(
    '#type' => 'html_tag',
    '#tag' => 'link',
    '#attributes' => array(
      'href' =>  'https://fonts.googleapis.com/css?family=Source+Sans+Pro:400,400i,700,700i&amp;subset=latin-ext,vietnamese',
      'rel' => 'stylesheet',
      'type' => 'text/css'
    )
  );
  
  $fontCssLinkRobotoSlab = array(
    '#type' => 'html_tag',
    '#tag' => 'link',
    '#attributes' => array(
      'href' =>  'https://fonts.googleapis.com/css?family=Roboto+Slab:400,700&amp;subset=cyrillic,cyrillic-ext,greek,greek-ext,latin-ext,vietnamese',
      'rel' => 'stylesheet',
      'type' => 'text/css'
    )
  );  
  
  $fontCssLinkSourceCodePro = array(
    '#type' => 'html_tag',
    '#tag' => 'link',
    '#attributes' => array(
      'href' =>  'https://fonts.googleapis.com/css?family=Source+Code+Pro:400,700&amp;subset=latin-ext',
      'rel' => 'stylesheet',
      'type' => 'text/css'
    )
  );  
  
  // Add header meta tag for IE to head
  drupal_add_html_head($fontCssLinkSourceSansPro, 'fontCssLinkSourceSansPro');
  drupal_add_html_head($fontCssLinkRobotoSlab, 'fontCssLinkRobotoSlab');
  drupal_add_html_head($fontCssLinkRobotoSlab, 'fontCssLinkSourceCodePro');
}

/**
 * Overrides theme_menu_link().
 */
function CLARIN_Horizon_menu_link__menu_block($variables) {
	return theme_menu_link($variables);
}
?>
