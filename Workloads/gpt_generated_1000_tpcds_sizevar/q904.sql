WITH catalog_part AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_ext_sales_price,
    cp.cp_department,
    cp.cp_catalog_number,
    cp.cp_type,
    w.w_warehouse_sk,
    w.w_warehouse_name
  FROM catalog_sales cs
  RIGHT OUTER JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  WHERE cp.cp_catalog_number IN (4, 15, 18)
    AND cs.cs_ext_sales_price > 100
    AND cs.cs_quantity BETWEEN 1 AND 10
    AND cp.cp_department IS NOT NULL
    AND cs.cs_sold_date_sk >= 2450905
    AND cp.cp_type = 'catalog'
),
web_part AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    w.w_warehouse_sk,
    w.w_warehouse_name,
    w.w_state,
    wr.wr_return_quantity,
    wr.wr_net_loss
  FROM web_sales ws
  INNER JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  FULL OUTER JOIN web_returns wr
    ON ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_order_number = wr.wr_order_number
  WHERE ws.ws_ext_sales_price > 50
    AND ws.ws_quantity BETWEEN 1 AND 5
    AND w.w_state = 'CA'
    AND ws.ws_sold_date_sk >= 2450905
    AND ws.ws_list_price > 20
    AND ws.ws_promo_sk IS NOT NULL
),
order_diff AS (
  SELECT cs_order_number FROM (
    SELECT cs.cs_order_number AS cs_order_number FROM catalog_sales cs WHERE cs.cs_ext_discount_amt > 0
    EXCEPT
    SELECT ws.ws_order_number FROM web_sales ws WHERE ws.ws_ext_discount_amt > 0
  )
),
final AS (
  SELECT
    COALESCE(cp.w_warehouse_sk, wp.w_warehouse_sk) AS warehouse_sk,
    COALESCE(cp.w_warehouse_name, wp.w_warehouse_name) AS warehouse_name,
    cp.cs_order_number,
    wp.ws_order_number,
    cp.cs_ext_sales_price,
    wp.ws_ext_sales_price,
    CASE
      WHEN cp.cs_quantity IS NULL THEN 'WebOnly'
      WHEN wp.ws_quantity IS NULL THEN 'CatalogOnly'
      ELSE 'Both'
    END AS source_type,
    ROW_NUMBER() OVER (
      PARTITION BY COALESCE(cp.w_warehouse_sk, wp.w_warehouse_sk)
      ORDER BY (COALESCE(cp.cs_ext_sales_price, 0) + COALESCE(wp.ws_ext_sales_price, 0)) DESC
    ) AS rn,
    RANK() OVER (
      ORDER BY (COALESCE(cp.cs_ext_sales_price, 0) + COALESCE(wp.ws_ext_sales_price, 0)) DESC
    ) AS revenue_rank,
    SUM(COALESCE(cp.cs_ext_sales_price, 0) + COALESCE(wp.ws_ext_sales_price, 0)) OVER (
      PARTITION BY COALESCE(cp.w_warehouse_sk, wp.w_warehouse_sk)
    ) AS warehouse_total_sales
  FROM catalog_part cp
  FULL OUTER JOIN web_part wp
    ON cp.w_warehouse_sk = wp.w_warehouse_sk
  WHERE EXISTS (
          SELECT 1 FROM web_returns wr
          WHERE wr.wr_order_number = cp.cs_order_number
             OR wr.wr_order_number = wp.ws_order_number
        )
    AND (
          cp.cs_order_number IN (SELECT cs_order_number FROM order_diff)
          OR wp.ws_order_number IN (SELECT cs_order_number FROM order_diff)
        )
)
SELECT *
FROM final
WHERE rn <= 100
ORDER BY warehouse_total_sales DESC
LIMIT 100
