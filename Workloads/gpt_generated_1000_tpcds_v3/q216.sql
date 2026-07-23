WITH ss_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(ss_quantity) AS total_quantity,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    WHERE ss_net_paid_inc_tax > 0
      AND ss_quantity >= 1
      AND ss_ext_wholesale_cost > 0
    GROUP BY ss_item_sk
),
cr_agg AS (
    SELECT
        cr_item_sk,
        cr_call_center_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_reversed_charge) AS total_rev_charge,
        COUNT(*) AS return_cnt
    FROM catalog_returns
    WHERE cr_return_amount > 100
      AND cr_reversed_charge > 10
      AND cr_return_quantity > 0
    GROUP BY cr_item_sk, cr_call_center_sk
),
wr_agg AS (
    SELECT
        wr_item_sk,
        SUM(wr_return_amt) AS total_web_return_amt,
        COUNT(*) AS web_return_cnt
    FROM web_returns
    WHERE wr_return_amt > 0
      AND wr_return_quantity > 0
      AND wr_fee > 0
    GROUP BY wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_brand,
    cc.cc_name AS call_center_name,
    ss_agg.total_sales_inc_tax,
    ss_agg.total_quantity,
    ss_agg.total_profit,
    cr_agg.total_return_amount,
    cr_agg.total_rev_charge,
    wr_agg.total_web_return_amt,
    CASE
        WHEN ss_agg.total_profit > 50000 THEN 'High'
        WHEN ss_agg.total_profit BETWEEN 20000 AND 50000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (ORDER BY ss_agg.total_profit DESC) AS profit_rank,
    AVG(ss_agg.total_profit) OVER (
        ORDER BY ss_agg.total_profit DESC
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS profit_moving_avg,
    (SELECT AVG(i_current_price) FROM item) AS avg_item_price
FROM ss_agg
JOIN item i ON ss_agg.ss_item_sk = i.i_item_sk
LEFT JOIN cr_agg ON cr_agg.cr_item_sk = i.i_item_sk
LEFT JOIN call_center cc ON cr_agg.cr_call_center_sk = cc.cc_call_center_sk
LEFT JOIN wr_agg ON wr_agg.wr_item_sk = i.i_item_sk
WHERE i.i_category = 'Electronics'
  AND i.i_current_price BETWEEN 100 AND 2000
  AND cc.cc_division IN (1, 2, 3)
  AND cc.cc_suite_number = 'Suite M'
  AND cc.cc_rec_start_date >= DATE '2001-01-01'
  AND cc.cc_rec_end_date <= DATE '2002-12-31'
ORDER BY profit_rank
LIMIT 100
