WITH
store_joined AS (
    SELECT
        COALESCE(ss.ss_sold_date_sk, sr.sr_returned_date_sk) AS date_sk,
        COALESCE(ss.ss_ticket_number, sr.sr_ticket_number) AS trans_id,
        COALESCE(ss.ss_net_paid, 0) - COALESCE(sr.sr_return_amt_inc_tax, 0) AS net_amount,
        ss.ss_customer_sk AS customer_sk,
        COALESCE(ss.ss_item_sk, sr.sr_item_sk) AS item_sk
    FROM store_sales ss
    FULL OUTER JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
),
store_enriched AS (
    SELECT
        d.d_date AS sale_date,
        'store' AS channel,
        sj.net_amount,
        sj.customer_sk,
        sj.item_sk
    FROM store_joined sj
    LEFT JOIN date_dim d
        ON sj.date_sk = d.d_date_sk
    LEFT JOIN item i
        ON sj.item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
),
web_joined AS (
    SELECT
        COALESCE(ws.ws_sold_date_sk, wr.wr_returned_date_sk) AS date_sk,
        COALESCE(ws.ws_order_number, wr.wr_order_number) AS trans_id,
        COALESCE(ws.ws_net_paid, 0) - COALESCE(wr.wr_return_amt_inc_tax, 0) AS net_amount,
        ws.ws_bill_customer_sk AS customer_sk,
        COALESCE(ws.ws_item_sk, wr.wr_item_sk) AS item_sk
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
),
web_enriched AS (
    SELECT
        d.d_date AS sale_date,
        'web' AS channel,
        wj.net_amount,
        wj.customer_sk,
        wj.item_sk
    FROM web_joined wj
    LEFT JOIN date_dim d
        ON wj.date_sk = d.d_date_sk
    LEFT JOIN item i
        ON wj.item_sk = i.i_item_sk
    WHERE d.d_year = 2002
      AND i.i_current_price > (SELECT AVG(i2.i_current_price) FROM item i2)
),
unioned AS (
    SELECT sale_date, channel, net_amount, customer_sk, item_sk
    FROM store_enriched
    UNION ALL
    SELECT sale_date, channel, net_amount, customer_sk, item_sk
    FROM web_enriched
),
aggregated AS (
    SELECT
        sale_date,
        channel,
        SUM(net_amount) AS total_net_amount,
        COUNT(DISTINCT customer_sk) AS distinct_customers,
        CASE WHEN SUM(net_amount) >= 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        GROUPING(sale_date) AS grp_sale_date,
        GROUPING(channel) AS grp_channel
    FROM unioned
    GROUP BY ROLLUP(sale_date, channel)
)
SELECT
    sale_date,
    channel,
    total_net_amount,
    distinct_customers,
    profit_flag,
    ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_amount DESC) AS rank_by_net_amount,
    grp_sale_date,
    grp_channel
FROM aggregated
ORDER BY sale_date NULLS LAST, channel
LIMIT 100
