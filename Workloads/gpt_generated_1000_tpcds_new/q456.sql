WITH unified AS (
  -- Catalog sales branch with returns and return reasons
  SELECT
    d.d_year                                   AS d_year,
    i.i_brand                                  AS i_brand,
    i.i_category                               AS i_category,
    (cs.cs_ext_sales_price - COALESCE(cr.cr_return_amount, 0)) AS sales_amount,
    cs.cs_quantity                             AS quantity,
    (cs.cs_net_profit - COALESCE(cr.cr_net_loss, 0))        AS profit,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END   AS promo_active_flag,
    r.r_reason_desc                           AS reason_desc
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                               AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#45'
    AND cp.cp_catalog_number = 12
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 50000

  UNION DISTINCT

  -- Store sales branch
  SELECT
    d.d_year                                   AS d_year,
    i.i_brand                                  AS i_brand,
    i.i_category                               AS i_category,
    ss.ss_ext_sales_price                     AS sales_amount,
    ss.ss_quantity                             AS quantity,
    ss.ss_net_profit                          AS profit,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END   AS promo_active_flag,
    CAST(NULL AS varchar)                     AS reason_desc
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#45'
    AND s.s_state = 'CA'
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 50000

  UNION DISTINCT

  -- Web sales branch
  SELECT
    d.d_year                                   AS d_year,
    i.i_brand                                  AS i_brand,
    i.i_category                               AS i_category,
    ws.ws_ext_sales_price                     AS sales_amount,
    ws.ws_quantity                             AS quantity,
    ws.ws_net_profit                          AS profit,
    CASE WHEN p.p_discount_active = 'Y' THEN 1 ELSE 0 END   AS promo_active_flag,
    CAST(NULL AS varchar)                     AS reason_desc
  FROM web_sales ws
  JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE d.d_year = 2001
    AND i.i_brand = 'Brand#45'
    AND wp.wp_type = 'content'
    AND we.web_open_date_sk = d.d_date_sk
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 50000
)
SELECT
  d_year,
  i_brand,
  i_category,
  SUM(sales_amount)                         AS total_sales,
  AVG(profit)                               AS avg_profit,
  COUNT(*)                                  AS txn_count,
  SUM(CASE WHEN promo_active_flag = 1 THEN sales_amount ELSE 0 END) AS promo_sales
FROM unified
GROUP BY GROUPING SETS (
  (d_year, i_brand, i_category),
  (d_year, i_brand),
  (d_year)
)
ORDER BY total_sales DESC
LIMIT 100
