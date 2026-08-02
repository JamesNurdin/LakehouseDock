WITH item_attrs AS (
    SELECT
        i_item_sk,
        ARRAY[i_color, i_size] AS attributes
    FROM item
),
base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_ticket_number,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_store_sk,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_return_amount,
        sr.sr_return_amt,
        i.i_category,
        i.i_brand,
        i.i_item_sk AS i_item_sk,
        i.i_current_price,
        i.i_rec_start_date,
        i.i_rec_end_date,
        c.c_customer_sk,
        c.c_birth_month,
        c.c_email_address,
        s.s_store_name,
        s.s_state,
        s.s_gmt_offset,
        td.t_hour,
        td.t_shift
    FROM store_sales ss
    INNER JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    INNER JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    INNER JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    INNER JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = i.i_item_sk
        AND sr.sr_return_time_sk = td.t_time_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_store_sk = s.s_store_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_item_sk = i.i_item_sk
        AND cr.cr_refunded_customer_sk = c.c_customer_sk
        AND cr.cr_returned_time_sk = td.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    WHERE
        i.i_category = 'Electronics'
        AND i.i_current_price > 100.00
        AND s.s_state = 'CA'
        AND s.s_gmt_offset >= -8
        AND c.c_birth_month IN (1, 12)
        AND td.t_shift = 'Night'
        AND i.i_rec_start_date >= DATE '2000-01-01'
        AND i.i_rec_end_date < DATE '2025-12-31'
        AND NOT EXISTS (
            SELECT 1 FROM store_returns sr2
            WHERE sr2.sr_customer_sk = c.c_customer_sk
              AND sr2.sr_return_quantity > 0
        )
),
agg1 AS (
    SELECT
        s_store_name,
        s_state,
        i_category,
        i_brand,
        MIN(i_item_sk) AS i_item_sk,
        date_trunc('month', date_add('day', ss_sold_date_sk, DATE '2000-01-01')) AS month,
        SUM(ss_ext_sales_price) AS total_store_sales,
        SUM(ws_ext_sales_price) AS total_web_sales,
        SUM(coalesce(cr_return_amount, 0) + coalesce(sr_return_amt, 0)) AS total_return_amount,
        SUM(ss_net_profit) + SUM(ws_net_profit) AS total_net_profit
    FROM base
    GROUP BY
        s_store_name,
        s_state,
        i_category,
        i_brand,
        date_trunc('month', date_add('day', ss_sold_date_sk, DATE '2000-01-01'))
),
final AS (
    SELECT
        a.s_store_name,
        a.s_state,
        a.i_category,
        a.i_brand,
        a.month,
        a.total_store_sales,
        a.total_web_sales,
        a.total_return_amount,
        a.total_net_profit,
        a.total_store_sales + a.total_web_sales - a.total_return_amount AS net_rev,
        RANK() OVER (PARTITION BY a.i_category ORDER BY a.total_net_profit DESC) AS profit_rank,
        a.i_item_sk,
        (SELECT AVG(total_net_profit) FROM agg1) AS avg_net_profit
    FROM agg1 a
)
SELECT DISTINCT
    f.s_store_name,
    f.s_state,
    f.i_category,
    f.i_brand,
    f.month,
    f.total_store_sales,
    f.total_web_sales,
    f.total_return_amount,
    f.total_net_profit,
    f.net_rev,
    f.profit_rank,
    attr.attribute,
    f.avg_net_profit
FROM final f
JOIN item_attrs ia ON ia.i_item_sk = f.i_item_sk
CROSS JOIN UNNEST(ia.attributes) AS attr(attribute)
WHERE f.profit_rank <= 10
ORDER BY f.total_net_profit DESC
LIMIT 100
