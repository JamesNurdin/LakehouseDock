WITH cr_agg AS (
    SELECT
        cr_item_sk,
        cr_reason_sk,
        SUM(cr_return_amount) AS total_ret_amount,
        SUM(cr_return_quantity) AS total_ret_qty
    FROM catalog_returns
    WHERE cr_return_amount > 50
      AND cr_return_quantity > 0
      AND cr_reason_sk IS NOT NULL
      AND cr_item_sk IS NOT NULL
    GROUP BY cr_item_sk, cr_reason_sk
)
SELECT
    w.w_warehouse_name,
    w.w_city,
    cc.cc_name,
    i.i_brand,
    r.r_reason_desc,
    cr_agg.total_ret_amount,
    cr_agg.total_ret_qty,
    SUM(cs.cs_net_profit) AS total_net_profit,
    LAG(cr_agg.total_ret_amount) OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY cr_agg.total_ret_amount DESC
    ) AS lag_ret_amount
FROM cr_agg
JOIN item i
    ON cr_agg.cr_item_sk = i.i_item_sk
JOIN reason r
    ON cr_agg.cr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
WHERE w.w_county = 'Walker County'
  AND cc.cc_state = 'CA'
  AND i.i_container = 'Unknown'
  AND r.r_reason_desc LIKE '%fault%'
GROUP BY
    w.w_warehouse_name,
    w.w_city,
    cc.cc_name,
    i.i_brand,
    r.r_reason_desc,
    cr_agg.total_ret_amount,
    cr_agg.total_ret_qty
HAVING SUM(cs.cs_net_profit) > 1000
ORDER BY total_net_profit DESC
LIMIT 100
