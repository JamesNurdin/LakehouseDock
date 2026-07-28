WITH filtered_sales AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_call_center_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_coupon_amt
    FROM catalog_sales cs
    WHERE cs.cs_net_paid > 5000
      AND cs.cs_coupon_amt > 100
)
SELECT
    p.p_promo_name,
    cc.cc_name,
    ws.web_name,
    r_sr.r_reason_desc,
    SUM(fs.cs_net_paid)                         AS total_net_paid,
    SUM(fs.cs_ext_discount_amt)                 AS total_discount,
    COUNT(DISTINCT fs.cs_order_number)          AS distinct_orders,
    SUM(sr.sr_net_loss)                         AS total_store_return_loss,
    SUM(wr.wr_net_loss)                         AS total_web_return_loss,
    AVG(inv.inv_quantity_on_hand)               AS avg_inventory_on_hand,
    MIN(d.d_date)                               AS min_transaction_date,
    MAX(d.d_date)                               AS max_transaction_date,
    (SELECT MAX(d2.d_date) FROM date_dim d2 WHERE d2.d_year = 2002) AS latest_date_2002
FROM filtered_sales fs
JOIN date_dim d               ON fs.cs_sold_date_sk = d.d_date_sk
JOIN call_center cc           ON fs.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p              ON fs.cs_promo_sk = p.p_promo_sk
LEFT JOIN store_returns sr   ON sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r_sr        ON sr.sr_reason_sk = r_sr.r_reason_sk
LEFT JOIN web_returns wr     ON wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN reason r_wr        ON wr.wr_reason_sk = r_wr.r_reason_sk
LEFT JOIN inventory inv       ON inv.inv_date_sk = d.d_date_sk
LEFT JOIN web_page wp         ON wp.wp_access_date_sk = d.d_date_sk
LEFT JOIN web_site ws         ON ws.web_open_date_sk = d.d_date_sk
WHERE cc.cc_state = 'CA'
  AND p.p_discount_active = 'Y'
  AND ws.web_manager IN ('John Ward', 'Peter Cassidy')
  AND inv.inv_quantity_on_hand > 0
  AND d.d_year = 2001
GROUP BY p.p_promo_name, cc.cc_name, ws.web_name, r_sr.r_reason_desc
HAVING SUM(fs.cs_net_paid) > 100000
ORDER BY total_net_paid DESC
LIMIT 100
