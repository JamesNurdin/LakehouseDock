WITH store_filtered AS (
    SELECT
        s_store_sk,
        s_store_id,
        s_state,
        s_city,
        s_division_id,
        s_gmt_offset,
        s_rec_start_date
    FROM store
    WHERE s_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
        AND s_division_id BETWEEN 1 AND 5
        AND s_gmt_offset >= -5
        AND s_rec_start_date >= DATE '1998-01-01'
),
sales_filtered AS (
    SELECT
        ss_store_sk,
        ss_sales_price,
        ss_quantity,
        ss_net_profit
    FROM store_sales
    WHERE ss_sales_price > 5
        AND ss_quantity >= 1
        AND ss_net_profit > 0
)
SELECT
    COALESCE(sf.s_store_id, 'UNKNOWN') AS store_id,
    sf.s_state,
    sf.s_city,
    sf.s_division_id,
    SUM(sf_sales.ss_sales_price * sf_sales.ss_quantity) AS total_sales_amount,
    SUM(sf_sales.ss_net_profit) AS total_net_profit,
    ROW_NUMBER() OVER (ORDER BY SUM(sf_sales.ss_net_profit) DESC) AS global_row_num,
    RANK() OVER (PARTITION BY sf.s_state ORDER BY SUM(sf_sales.ss_net_profit) DESC) AS state_rank,
    SUM(SUM(sf_sales.ss_net_profit)) OVER (
        ORDER BY SUM(sf_sales.ss_net_profit) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit
FROM store_filtered sf
FULL OUTER JOIN sales_filtered sf_sales
    ON sf.s_store_sk = sf_sales.ss_store_sk
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss2
    WHERE ss2.ss_store_sk = sf.s_store_sk
        AND ss2.ss_net_profit > 100
)
GROUP BY
    COALESCE(sf.s_store_id, 'UNKNOWN'),
    sf.s_state,
    sf.s_city,
    sf.s_division_id
ORDER BY total_net_profit DESC
LIMIT 100
