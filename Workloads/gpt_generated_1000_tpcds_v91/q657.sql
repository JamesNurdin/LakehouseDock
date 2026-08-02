WITH sold_not_returned AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT sr_item_sk
    FROM store_returns
),
base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_promo_sk,
        t.t_hour,
        t.t_minute,
        c.c_customer_id,
        c.c_preferred_cust_flag,
        p.p_promo_id,
        p.p_cost,
        p.p_channel_event,
        p.p_promo_sk,
        wsite.web_site_id,
        wp.wp_type,
        r.r_reason_desc,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        cs.cs_quantity AS catalog_quantity,
        cs.cs_ext_sales_price AS catalog_ext_sales_price,
        cs.cs_net_profit AS catalog_net_profit,
        (SELECT SUM(wr2.wr_refunded_cash)
         FROM web_returns wr2
         WHERE wr2.wr_refunded_customer_sk = ss.ss_customer_sk) AS total_refunded_cash
    FROM store_sales ss
    JOIN sold_not_returned nri
        ON ss.ss_item_sk = nri.ss_item_sk
    JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    CROSS JOIN LATERAL (
        SELECT p.p_promo_id, p.p_cost, p.p_channel_event, p.p_promo_sk
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
    ) p
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    LEFT JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = ss.ss_customer_sk
        AND cs.cs_sold_time_sk = ss.ss_sold_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_bill_customer_sk = ss.ss_customer_sk
        AND ws.ws_sold_time_sk = ss.ss_sold_time_sk
    LEFT JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    WHERE
        p.p_channel_event = 'N'
        AND p.p_cost > 1000
        AND c.c_preferred_cust_flag = 'Y'
        AND t.t_hour BETWEEN 9 AND 17
        AND ss.ss_quantity >= 2
        AND ws.ws_ext_sales_price > 150
        AND wp.wp_type = 'product'
        AND (r.r_reason_desc IS NULL OR r.r_reason_desc <> 'Other')
),
agg AS (
    SELECT
        p_promo_id,
        p_cost,
        t_hour,
        COUNT(DISTINCT ss_customer_sk) AS distinct_customers,
        SUM(ss_ext_sales_price) AS store_sales_total,
        SUM(ws_ext_sales_price) AS web_sales_total,
        SUM(catalog_ext_sales_price) AS catalog_sales_total,
        SUM(ss_net_profit + ws_net_profit + catalog_net_profit) AS total_net_profit,
        AVG(ss_quantity) AS avg_store_quantity
    FROM base
    GROUP BY p_promo_id, p_cost, t_hour
)
SELECT
    agg.p_promo_id,
    agg.t_hour,
    agg.store_sales_total,
    agg.web_sales_total,
    agg.catalog_sales_total,
    agg.total_net_profit,
    agg.distinct_customers,
    agg.avg_store_quantity,
    (SELECT SUM(sr2.sr_return_amt)
     FROM store_returns sr2
     JOIN store_sales ss2 ON sr2.sr_ticket_number = ss2.ss_ticket_number
     JOIN promotion p2 ON ss2.ss_promo_sk = p2.p_promo_sk
     WHERE p2.p_promo_id = agg.p_promo_id) AS total_store_returns,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     JOIN web_sales ws2 ON wr2.wr_order_number = ws2.ws_order_number
     JOIN promotion p2 ON ws2.ws_promo_sk = p2.p_promo_sk
     WHERE p2.p_promo_id = agg.p_promo_id) AS total_web_returns
FROM agg
WHERE agg.total_net_profit > 10000
ORDER BY agg.total_net_profit DESC
LIMIT 100
