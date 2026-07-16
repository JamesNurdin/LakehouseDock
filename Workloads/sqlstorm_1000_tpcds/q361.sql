WITH sales AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_profit,
        SUM(ss.ss_quantity) AS total_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        i.i_item_sk,
        i.i_product_name
),
returns AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        r.sr_store_sk,
        r.sr_item_sk,
        SUM(r.sr_return_quantity) AS return_quantity,
        SUM(r.sr_net_loss) AS return_loss
    FROM store_returns r
    JOIN date_dim d ON r.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
    GROUP BY
        d.d_year,
        d.d_month_seq,
        r.sr_store_sk,
        r.sr_item_sk
),
sales_with_returns AS (
    SELECT
        s.d_year,
        s.d_month_seq,
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.i_item_sk,
        s.i_product_name,
        s.total_net_paid,
        s.total_profit,
        s.total_quantity,
        COALESCE(r.return_quantity, 0) AS item_return_quantity,
        COALESCE(r.return_loss, 0) AS item_return_loss,
        s.total_profit - COALESCE(r.return_loss, 0) AS net_profit_after_returns
    FROM sales s
    LEFT JOIN returns r
        ON s.d_year = r.d_year
        AND s.d_month_seq = r.d_month_seq
        AND s.s_store_sk = r.sr_store_sk
        AND s.i_item_sk = r.sr_item_sk
),
item_ranking AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_sk,
        i_item_sk,
        i_product_name,
        net_profit_after_returns,
        ROW_NUMBER() OVER (PARTITION BY s_store_sk, d_year, d_month_seq ORDER BY net_profit_after_returns DESC) AS rn
    FROM sales_with_returns
),
top_items AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_sk,
        ARRAY_AGG(ROW(i_product_name, net_profit_after_returns) ORDER BY net_profit_after_returns DESC) FILTER (WHERE rn <= 5) AS top_items
    FROM item_ranking
    GROUP BY
        d_year,
        d_month_seq,
        s_store_sk
),
store_month_agg AS (
    SELECT
        d_year,
        d_month_seq,
        s_store_sk,
        s_store_id,
        s_store_name,
        SUM(total_net_paid) AS store_total_net_paid,
        SUM(total_quantity) AS store_total_quantity,
        SUM(item_return_quantity) AS store_total_return_quantity,
        SUM(net_profit_after_returns) AS store_net_profit_after_returns
    FROM sales_with_returns
    GROUP BY
        d_year,
        d_month_seq,
        s_store_sk,
        s_store_id,
        s_store_name
)
SELECT
    sma.d_year,
    sma.d_month_seq,
    sma.s_store_id,
    sma.s_store_name,
    sma.store_total_net_paid,
    sma.store_total_quantity,
    sma.store_total_return_quantity,
    sma.store_net_profit_after_returns,
    ti.top_items
FROM store_month_agg sma
LEFT JOIN top_items ti
    ON sma.d_year = ti.d_year
    AND sma.d_month_seq = ti.d_month_seq
    AND sma.s_store_sk = ti.s_store_sk
ORDER BY sma.d_year, sma.d_month_seq, sma.s_store_id
