WITH filtered_sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cc.cc_state,
        SUM(s.ss_ext_sales_price) AS total_sales,
        AVG(s.ss_net_profit) AS avg_profit,
        COUNT(*) AS txn_cnt,
        MIN(s.ss_ext_discount_amt) AS min_discount,
        MAX(s.ss_ext_list_price) AS max_list_price,
        CASE 
            WHEN AVG(s.ss_net_profit) > 1000 THEN 'HIGH'
            WHEN AVG(s.ss_net_profit) > 0 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1220
        AND d.d_dow IN (1, 2, 3)
        AND s.ss_ext_sales_price > 500
        AND s.ss_quantity >= 2
        AND s.ss_net_profit > 0
        AND cc.cc_state = 'CA'
        AND cc.cc_gmt_offset = -5.00
        AND cc.cc_hours = '8AM-4PM'
        AND EXISTS (
            SELECT 1
            FROM call_center cc2
            WHERE cc2.cc_open_date_sk = d.d_date_sk
              AND cc2.cc_class = 'Corporate'
        )
    GROUP BY d.d_year, d.d_month_seq, cc.cc_state
)
SELECT
    fs.d_year,
    fs.d_month_seq,
    fs.cc_state,
    fs.total_sales,
    fs.avg_profit,
    fs.txn_cnt,
    fs.min_discount,
    fs.max_list_price,
    fs.profit_category,
    ROW_NUMBER() OVER (PARTITION BY fs.d_year ORDER BY fs.total_sales DESC) AS rn_yearly,
    (SELECT MAX(cc_employees) FROM call_center WHERE cc_state = fs.cc_state) AS max_employees_state
FROM filtered_sales fs
ORDER BY fs.total_sales DESC
LIMIT 100
