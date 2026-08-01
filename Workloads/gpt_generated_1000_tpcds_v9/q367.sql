WITH sales AS (
    SELECT
        d.d_date AS txn_date,
        t.t_time AS txn_time,
        ss.ss_item_sk AS item_sk,
        ss.ss_store_sk AS store_sk,
        ss.ss_net_paid AS net_amount,
        cp.cp_description,
        'sale' AS txn_type
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cd.cd_education_status = 'College'
), returns AS (
    SELECT
        d.d_date AS txn_date,
        t.t_time AS txn_time,
        sr.sr_item_sk AS item_sk,
        sr.sr_store_sk AS store_sk,
        -sr.sr_net_loss AS net_amount,
        cp.cp_description,
        'return' AS txn_type
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cp.cp_end_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cd.cd_education_status = 'College'
), combined AS (
    SELECT
        s.txn_date,
        s.txn_time,
        s.item_sk,
        s.store_sk,
        s.net_amount,
        s.cp_description,
        s.txn_type
    FROM sales s
    UNION ALL
    SELECT
        r.txn_date,
        r.txn_time,
        r.item_sk,
        r.store_sk,
        r.net_amount,
        r.cp_description,
        r.txn_type
    FROM returns r
)
SELECT
    c.txn_date,
    c.txn_time,
    c.item_sk,
    c.store_sk,
    c.net_amount,
    c.txn_type,
    cat.category,
    SUM(c.net_amount) OVER (
        PARTITION BY c.item_sk
        ORDER BY c.txn_date, c.txn_time
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net,
    LAG(c.net_amount) OVER (
        PARTITION BY c.item_sk
        ORDER BY c.txn_date, c.txn_time
    ) AS prev_net
FROM combined c
CROSS JOIN UNNEST(split(c.cp_description, ',')) AS cat (category)
WHERE trim(cat.category) <> ''
ORDER BY c.txn_date, c.txn_time, c.item_sk
