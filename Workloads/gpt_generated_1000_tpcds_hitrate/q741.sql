WITH base AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_company_name,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        i.i_category_id,
        i.i_size,
        i.i_item_id,
        wr.wr_return_amt,
        wr.wr_refunded_cash
    FROM tpcds.call_center AS cc
    FULL OUTER JOIN tpcds.catalog_sales AS cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN tpcds.item AS i
        ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN tpcds.web_returns AS wr
        ON i.i_item_sk = wr.wr_item_sk
    WHERE i.i_category_id IN (3, 7, 9)
      AND i.i_size IN ('small', 'medium', 'large')
      AND cs.cs_quantity > 1
      AND cc.cc_state = 'TX'
      AND cs.cs_net_profit > 0
),
agg1 AS (
    SELECT
        cc_call_center_sk,
        i_category_id,
        SUM(cs_net_profit) AS total_profit,
        SUM(wr_return_amt) AS total_return_amt,
        ARRAY_AGG(i_item_id) AS item_ids
    FROM base
    GROUP BY cc_call_center_sk, i_category_id
),
exploded AS (
    SELECT
        a.cc_call_center_sk,
        a.i_category_id,
        a.total_profit,
        a.total_return_amt,
        item_id
    FROM agg1 AS a
    CROSS JOIN UNNEST(a.item_ids) AS t(item_id)
),
ranked AS (
    SELECT
        e.*, 
        ROW_NUMBER() OVER (PARTITION BY e.cc_call_center_sk ORDER BY e.total_profit DESC) AS rn
    FROM exploded AS e
)
SELECT
    r.cc_call_center_sk,
    r.i_category_id,
    r.item_id,
    r.total_profit,
    r.total_return_amt
FROM ranked AS r
WHERE r.rn <= 3
  AND r.total_profit > (SELECT AVG(total_profit) FROM agg1)
ORDER BY r.total_profit DESC
LIMIT 100
