WITH base AS (
    SELECT
        s.s_state AS store_state,
        w.w_state AS warehouse_state,
        CASE WHEN cs.cs_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        sr.sr_return_amt,
        wr.wr_return_amt,
        cs.cs_net_profit,
        cs.cs_quantity,
        i.i_product_name,
        split(i.i_product_name, ' ') AS product_words
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td_cs
        ON cs.cs_sold_time_sk = td_cs.t_time_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
    JOIN time_dim td_sr
        ON sr.sr_return_time_sk = td_sr.t_time_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_sr
        ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
    JOIN time_dim td_wr
        ON wr.wr_returned_time_sk = td_wr.t_time_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE i.i_current_price > 50.00                     -- predicate 1
      AND w.w_state = 'CA'                              -- predicate 2
      AND s.s_state = 'TX'                              -- predicate 3
      AND r_sr.r_reason_desc = 'Customer Not Satisfied' -- predicate 4
      AND td_cs.t_hour BETWEEN 9 AND 17                -- predicate 5
      AND i.i_rec_start_date >= DATE '1997-01-01'      -- predicate 6
      AND cs.cs_quantity >= 3                         -- predicate 7
),
unnested AS (
    SELECT
        base.*,
        word
    FROM base
    CROSS JOIN UNNEST(base.product_words) AS t(word)
),
agg1 AS (
    SELECT
        store_state,
        warehouse_state,
        profit_flag,
        COUNT(DISTINCT cs_order_number) AS num_orders,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(sr_return_amt) AS total_store_returns,
        SUM(wr_return_amt) AS total_web_returns,
        AVG(cs_net_profit) AS avg_net_profit,
        COUNT(*) AS total_product_word_count
    FROM unnested
    GROUP BY ROLLUP (store_state, warehouse_state, profit_flag)
)
SELECT
    store_state,
    warehouse_state,
    profit_flag,
    num_orders,
    total_sales,
    total_store_returns,
    total_web_returns,
    avg_net_profit,
    total_product_word_count,
    CASE WHEN total_sales > 10000 THEN 'High' ELSE 'Low' END AS sales_category
FROM agg1
WHERE avg_net_profit > 0
ORDER BY store_state, warehouse_state, profit_flag
