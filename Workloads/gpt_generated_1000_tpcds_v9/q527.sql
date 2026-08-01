WITH base_sales AS (
    SELECT
        ss.ss_net_paid,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        w.web_city,
        cp.cp_department,
        d.d_quarter_seq,
        i.inv_quantity_on_hand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    JOIN web_site w ON w.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
      AND cp.cp_department = 'Electronics'
      AND w.web_city IN ('Shiloh', 'Georgetown')
      AND ss.ss_quantity > 5
      AND i.inv_quantity_on_hand < 100
)
SELECT
    web_city,
    cp_department,
    d_quarter_seq,
    SUM(ss_net_paid) AS total_net_paid,
    SUM(ss_net_profit) AS total_net_profit,
    COUNT(*) AS sales_cnt,
    AVG(ss_ext_discount_amt) AS avg_discount,
    CASE WHEN SUM(ss_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    RANK() OVER (PARTITION BY d_quarter_seq ORDER BY SUM(ss_net_paid) DESC) AS net_paid_rank,
    (
        SELECT MAX(ss2.ss_net_paid)
        FROM store_sales ss2
        JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
        WHERE d2.d_quarter_seq = base_sales.d_quarter_seq
    ) AS max_net_paid_in_quarter
FROM base_sales
GROUP BY GROUPING SETS (
    (web_city, cp_department, d_quarter_seq),
    (web_city, cp_department),
    (web_city),
    (cp_department),
    ()
)
ORDER BY d_quarter_seq, net_paid_rank
LIMIT 100
