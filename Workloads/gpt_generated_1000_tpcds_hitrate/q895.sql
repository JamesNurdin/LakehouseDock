WITH
  q1 AS (
    SELECT
      i.i_brand AS brand,
      i.i_category AS category,
      ws.ws_quantity AS quantity,
      ws.ws_sales_price AS sales_price,
      wr_agg.total_item_return AS total_item_return,
      r_web.r_reason_desc AS return_reason
    FROM web_sales ws
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      JOIN customer cust_bill ON ws.ws_bill_customer_sk = cust_bill.c_customer_sk
      JOIN customer cust_ship ON ws.ws_ship_customer_sk = cust_ship.c_customer_sk
      JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
      JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
      RIGHT OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
      LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
      LEFT JOIN LATERAL (
        SELECT sum(wr2.wr_return_amt) AS total_item_return
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
      ) wr_agg ON true
      FULL OUTER JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = cust_bill.c_customer_sk
      LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
      LEFT JOIN reason r_store ON sr.sr_reason_sk = r_store.r_reason_sk
      FULL OUTER JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
      LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
      LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
      LEFT JOIN reason r_cat ON cr.cr_reason_sk = r_cat.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2450825
  ),
  q2 AS (
    SELECT
      i.i_brand AS brand,
      i.i_category AS category,
      ws.ws_quantity AS quantity,
      ws.ws_sales_price AS sales_price,
      wr_agg.total_item_return AS total_item_return,
      r_web.r_reason_desc AS return_reason
    FROM web_sales ws
      JOIN item i ON ws.ws_item_sk = i.i_item_sk
      JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
      RIGHT OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
      LEFT JOIN reason r_web ON wr.wr_reason_sk = r_web.r_reason_sk
      LEFT JOIN LATERAL (
        SELECT sum(wr2.wr_return_amt) AS total_item_return
        FROM web_returns wr2
        WHERE wr2.wr_item_sk = i.i_item_sk
      ) wr_agg ON true
    WHERE ws.ws_net_profit > 0
  )
SELECT
  brand,
  category,
  SUM(quantity) AS total_quantity,
  SUM(sales_price) AS total_sales,
  SUM(total_item_return) AS total_returns,
  GROUPING(brand) AS brand_group,
  GROUPING(category) AS category_group,
  ROW_NUMBER() OVER (ORDER BY brand, category) AS rn
FROM (
  SELECT brand, category, quantity, sales_price, total_item_return
  FROM q1
  UNION DISTINCT
  SELECT brand, category, quantity, sales_price, total_item_return
  FROM q2
) u
GROUP BY ROLLUP (brand, category)
ORDER BY brand NULLS LAST, category NULLS LAST
