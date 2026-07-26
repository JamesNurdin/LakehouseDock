WITH item_store_agg AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS txn_cnt,
        SUM(ss.ss_quantity) AS total_qty
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
item_store_rank AS (
    SELECT
        isa.*, 
        DENSE_RANK() OVER (PARTITION BY isa.ss_store_sk ORDER BY isa.total_sales DESC) AS sales_rank
    FROM item_store_agg isa
),
item_demo AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        hd.hd_buy_potential,
        COUNT(*) AS demo_cnt
    FROM store_sales ss
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, hd.hd_buy_potential
),
item_customer AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        AVG(c.c_birth_year) AS avg_birth_year,
        COUNT(DISTINCT c.c_customer_sk) AS distinct_customers
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
item_time AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        t.t_hour,
        SUM(ss.ss_quantity) AS qty_by_hour
    FROM store_sales ss
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, t.t_hour
)
SELECT
    isr.ss_store_sk,
    isr.ss_item_sk,
    isr.total_sales,
    isr.total_profit,
    isr.txn_cnt,
    isr.total_qty,
    isr.sales_rank,
    CASE
        WHEN isr.total_profit / NULLIF(isr.total_sales, 0) > 0.2 THEN 'High Margin'
        WHEN isr.total_profit / NULLIF(isr.total_sales, 0) BETWEEN 0.1 AND 0.2 THEN 'Medium Margin'
        ELSE 'Low Margin'
    END AS profit_category,
    (
        SELECT it.t_hour
        FROM item_time it
        WHERE it.ss_store_sk = isr.ss_store_sk
          AND it.ss_item_sk = isr.ss_item_sk
        ORDER BY it.qty_by_hour DESC
        LIMIT 1
    ) AS peak_hour,
    ic.avg_birth_year,
    ic.distinct_customers,
    id.hd_buy_potential,
    id.demo_cnt,
    id.demo_cnt * 100.0 / SUM(id.demo_cnt) OVER (PARTITION BY isr.ss_store_sk, isr.ss_item_sk) AS buy_potential_pct
FROM item_store_rank isr
LEFT JOIN item_customer ic ON isr.ss_store_sk = ic.ss_store_sk AND isr.ss_item_sk = ic.ss_item_sk
LEFT JOIN item_demo id ON isr.ss_store_sk = id.ss_store_sk AND isr.ss_item_sk = id.ss_item_sk
ORDER BY isr.ss_store_sk, isr.sales_rank
LIMIT 100
