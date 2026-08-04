WITH
  intersect_items AS (
    SELECT ss.ss_item_sk AS item_sk
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    INTERSECT
    SELECT ws.ws_item_sk AS item_sk
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2002
  ),

  promo_sales AS (
    SELECT p.p_promo_id,
           COALESCE(SUM(ss.ss_ext_sales_price), 0) AS total_sales
    FROM promotion p
    RIGHT OUTER JOIN store_sales ss
      ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_id
  ),

  combined_returns AS (
    SELECT r.r_reason_desc,
           SUM(cr.cr_net_loss) AS catalog_loss,
           0 AS web_loss
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)customer')
    GROUP BY r.r_reason_desc

    UNION DISTINCT

    SELECT r.r_reason_desc,
           0 AS catalog_loss,
           SUM(wr.wr_net_loss) AS web_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%damage%'
    GROUP BY r.r_reason_desc
  ),

  final AS (
    SELECT
      ca.r_reason_desc,
      ca.catalog_loss,
      ca.web_loss,
      ps.p_promo_id,
      ps.total_sales,
      i.i_item_id,
      regexp_extract(i.i_item_desc, 'Brand: ([A-Za-z]+)', 1) AS brand_extracted,
      CONCAT(ca.r_reason_desc, ' - ', COALESCE(ps.p_promo_id, '')) AS reason_promo_key
    FROM combined_returns ca
    LEFT JOIN promo_sales ps
      ON ps.p_promo_id = SUBSTRING(ca.r_reason_desc FROM 1 FOR 5)
    JOIN intersect_items ii ON TRUE
    JOIN item i ON i.i_item_sk = ii.item_sk
    WHERE regexp_like(i.i_item_desc, 'Brand|Size')
      AND i.i_item_desc LIKE '%size%'
  )

SELECT
  reason_promo_key,
  catalog_loss,
  web_loss,
  total_sales,
  brand_extracted
FROM final
ORDER BY catalog_loss DESC, web_loss DESC
OFFSET 0 ROWS FETCH NEXT 20 ROWS ONLY
