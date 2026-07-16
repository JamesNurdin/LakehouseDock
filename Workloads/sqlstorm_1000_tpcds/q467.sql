WITH
sales_joined AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_sold_date_sk,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        ss.ss_ext_discount_amt,
        ss.ss_ext_sales_price,
        ss.ss_net_paid_inc_tax
    FROM store_sales ss
),
store_sales_enriched AS (
    SELECT
        sj.ss_store_sk,
        sj.ss_sold_date_sk,
        sj.ss_item_sk,
        sj.ss_quantity,
        sj.ss_net_profit,
        sj.ss_ext_discount_amt,
        sj.ss_ext_sales_price,
        sj.ss_net_paid_inc_tax,
        s.s_store_name,
        s.s_state,
        s.s_country,
        d.d_year,
        d.d_month_seq
    FROM sales_joined sj
    JOIN store s ON sj.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON sj.ss_sold_date_sk = d.d_date_sk
),
returns_agg AS (
    SELECT
        sr.sr_store_sk AS s_store_sk,
        d.d_year,
        d.d_month_seq,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_net_loss) AS total_return_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    GROUP BY sr.sr_store_sk, d.d_year, d.d_month_seq
),
item_profit AS (
    SELECT
        sse.ss_store_sk AS s_store_sk,
        sse.d_year,
        sse.d_month_seq,
        i.i_item_id,
        SUM(sse.ss_net_profit) AS item_net_profit,
        SUM(sse.ss_quantity) AS item_quantity
    FROM store_sales_enriched sse
    JOIN item i ON sse.ss_item_sk = i.i_item_sk
    GROUP BY sse.ss_store_sk, sse.d_year, sse.d_month_seq, i.i_item_id
),
item_rank AS (
    SELECT
        ip.*,
        ROW_NUMBER() OVER (PARTITION BY ip.s_store_sk, ip.d_year, ip.d_month_seq ORDER BY ip.item_net_profit DESC) AS rn
    FROM item_profit ip
),
store_month_agg AS (
    SELECT
        sse.ss_store_sk AS s_store_sk,
        sse.s_store_name,
        sse.s_state,
        sse.s_country,
        sse.d_year,
        sse.d_month_seq,
        SUM(sse.ss_quantity) AS total_quantity,
        SUM(sse.ss_net_paid_inc_tax) AS total_sales,
        SUM(sse.ss_net_profit) AS total_net_profit,
        SUM(sse.ss_ext_discount_amt) AS total_discount_amt,
        SUM(sse.ss_ext_sales_price) AS total_sales_price,
        SUM(sse.ss_ext_discount_amt) / NULLIF(SUM(sse.ss_ext_sales_price), 0) AS avg_discount_ratio,
        approx_percentile(sse.ss_net_profit, 0.5) AS median_net_profit
    FROM store_sales_enriched sse
    GROUP BY sse.ss_store_sk, sse.s_store_name, sse.s_state, sse.s_country, sse.d_year, sse.d_month_seq
)
SELECT
    sma.s_store_name,
    sma.s_state,
    sma.s_country,
    sma.d_year,
    sma.d_month_seq,
    sma.total_quantity,
    sma.total_sales,
    sma.total_net_profit,
    sma.total_discount_amt,
    sma.avg_discount_ratio,
    sma.median_net_profit,
    COALESCE(ra.total_return_qty, 0) AS total_return_quantity,
    COALESCE(ra.total_return_loss, 0) AS total_return_loss,
    sma.total_net_profit - COALESCE(ra.total_return_loss, 0) AS net_profit_after_returns,
    array_agg(ir.i_item_id) FILTER (WHERE ir.rn <= 5) AS top_5_items_by_profit,
    ROW_NUMBER() OVER (PARTITION BY sma.d_year, sma.d_month_seq ORDER BY sma.total_net_profit DESC) AS store_rank_in_month
FROM store_month_agg sma
LEFT JOIN returns_agg ra
    ON sma.s_store_sk = ra.s_store_sk
   AND sma.d_year = ra.d_year
   AND sma.d_month_seq = ra.d_month_seq
LEFT JOIN item_rank ir
    ON sma.s_store_sk = ir.s_store_sk
   AND sma.d_year = ir.d_year
   AND sma.d_month_seq = ir.d_month_seq
GROUP BY
    sma.s_store_sk,
    sma.s_store_name,
    sma.s_state,
    sma.s_country,
    sma.d_year,
    sma.d_month_seq,
    sma.total_quantity,
    sma.total_sales,
    sma.total_net_profit,
    sma.total_discount_amt,
    sma.avg_discount_ratio,
    sma.median_net_profit,
    ra.total_return_qty,
    ra.total_return_loss
