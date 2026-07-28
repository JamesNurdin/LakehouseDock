WITH sr AS (
    SELECT
        sr_returned_date_sk,
        sr_store_sk,
        sr_item_sk,
        sr_customer_sk,
        sr_cdemo_sk,
        sr_reason_sk,
        sr_net_loss,
        sr_return_quantity
    FROM store_returns
    WHERE sr_returned_date_sk BETWEEN 2451000 AND 2452000
)
SELECT
    s.s_store_name,
    i.i_product_name,
    ws.web_name,
    d.d_year,
    SUM(sr.sr_net_loss) AS total_net_loss,
    SUM(sr.sr_return_quantity) AS total_return_qty,
    RANK() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_net_loss) DESC) AS loss_rank_year,
    CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'High' ELSE 'Low' END AS loss_category
FROM sr
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
  ON sr.sr_cdemo_sk = cd.cd_demo_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN catalog_page cp
  ON cp.cp_start_date_sk = d.d_date_sk
   OR cp.cp_end_date_sk = d.d_date_sk
LEFT JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
LEFT JOIN web_site ws
  ON ws.web_open_date_sk = d.d_date_sk
WHERE i.i_current_price > 100
  AND s.s_tax_percentage > 0
  AND cd.cd_credit_rating = 'Excellent'
  AND r.r_reason_desc IS NOT NULL
  AND cp.cp_department = 'electronics'
  AND wp.wp_type = 'order'
GROUP BY
    s.s_store_name,
    i.i_product_name,
    ws.web_name,
    d.d_year
ORDER BY total_net_loss DESC
LIMIT 100
