WITH
  sales_agg AS (
    SELECT
      cc.cc_call_center_id,
      i.i_category,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ext_sales_price > 1000
      AND cs.cs_net_profit > 0
      AND cc.cc_state = 'CA'
      AND i.i_manager_id IN (13, 25, 40)
      AND i.i_rec_start_date >= DATE '1999-01-01'
      AND i.i_rec_end_date <= DATE '2002-12-31'
    GROUP BY cc.cc_call_center_id, i.i_category
  ),
  returns_agg AS (
    SELECT
      cc.cc_call_center_id,
      i.i_category,
      SUM(cr.cr_return_amount) AS total_returns,
      COUNT(*) AS return_cnt
    FROM catalog_returns cr
    RIGHT OUTER JOIN call_center cc
      ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 0
      AND cc.cc_country = 'United States'
      AND (cc.cc_sq_ft > 0 OR cc.cc_sq_ft IS NULL)
      AND i.i_category IS NOT NULL
      AND cr.cr_return_quantity >= 1
      AND cr.cr_order_number IS NOT NULL
    GROUP BY cc.cc_call_center_id, i.i_category
  ),
  combined AS (
    SELECT
      s.cc_call_center_id,
      s.i_category,
      s.total_sales,
      s.total_profit,
      s.sales_cnt,
      COALESCE(r.total_returns, 0) AS total_returns,
      COALESCE(r.return_cnt, 0) AS return_cnt,
      (s.total_sales - COALESCE(r.total_returns, 0)) AS net_sales
    FROM sales_agg s
    LEFT JOIN returns_agg r
      ON s.cc_call_center_id = r.cc_call_center_id
     AND s.i_category = r.i_category
  )
SELECT *
FROM (
  SELECT
    c.cc_call_center_id,
    c.i_category,
    AVG(c.net_sales) AS avg_net_sales,
    SUM(c.sales_cnt) AS total_transactions
  FROM combined c
  WHERE c.net_sales > 5000
    AND c.total_profit > 1000
    AND c.sales_cnt >= 10
    AND c.return_cnt < 5
    AND c.i_category NOT IN ('Books', 'Music')
    AND EXISTS (
          SELECT 1
          FROM call_center cc2
          WHERE cc2.cc_call_center_id = c.cc_call_center_id
            AND cc2.cc_gmt_offset BETWEEN -5 AND 0
        )
  GROUP BY c.cc_call_center_id, c.i_category
  HAVING AVG(c.net_sales) > 10000

  INTERSECT

  SELECT
    cc.cc_call_center_id,
    i.i_category,
    AVG(cs.cs_ext_sales_price - COALESCE(cr.cr_return_amount, 0)) AS avg_net_sales,
    SUM(cs.cs_quantity) AS total_transactions
  FROM catalog_sales cs
  LEFT JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
  JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  WHERE cs.cs_ext_sales_price > 2000
    AND cc.cc_state = 'TX'
    AND i.i_color = 'Red'
    AND cs.cs_quantity > 5
    AND cr.cr_return_amount IS NULL
    AND cc.cc_tax_percentage < 5.00
  GROUP BY cc.cc_call_center_id, i.i_category
  HAVING SUM(cs.cs_quantity) > 20
) AS intersected_result
ORDER BY avg_net_sales DESC
