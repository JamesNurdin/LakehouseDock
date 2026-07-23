WITH
store_agg AS (
    SELECT
        'store' AS channel_type,
        s.s_store_sk AS channel_key,
        ss.ss_sold_date_sk AS sold_date_sk,
        d_sold.d_date AS sold_date,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ss.ss_net_paid) AS net_sales,
        COALESCE(SUM(sr.sr_return_amt), 0) AS return_amount,
        d_sold.d_year AS year,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        r_store.r_reason_desc AS reason_desc
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ss.ss_sold_time_sk = t_sold.t_time_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    LEFT JOIN reason r_store
        ON sr.sr_reason_sk = r_store.r_reason_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_return
        ON sr.sr_returned_date_sk = d_return.d_date_sk
    GROUP BY
        s.s_store_sk,
        ss.ss_sold_date_sk,
        d_sold.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        d_sold.d_year,
        ca.ca_state,
        cd.cd_gender,
        r_store.r_reason_desc
),
web_agg AS (
    SELECT
        'web' AS channel_type,
        site.web_site_sk AS channel_key,
        ws.ws_sold_date_sk AS sold_date_sk,
        d_sold.d_date AS sold_date,
        i.i_item_sk AS item_sk,
        i.i_item_id AS item_id,
        i.i_brand AS brand,
        i.i_category AS category,
        SUM(ws.ws_net_paid) AS net_sales,
        COALESCE(SUM(wr.wr_return_amt), 0) AS return_amount,
        d_sold.d_year AS year,
        ca.ca_state AS state,
        cd.cd_gender AS gender,
        r_web.r_reason_desc AS reason_desc
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_site site
        ON ws.ws_web_site_sk = site.web_site_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    LEFT JOIN reason r_web
        ON wr.wr_reason_sk = r_web.r_reason_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d_return
        ON wr.wr_returned_date_sk = d_return.d_date_sk
    GROUP BY
        site.web_site_sk,
        ws.ws_sold_date_sk,
        d_sold.d_date,
        i.i_item_sk,
        i.i_item_id,
        i.i_brand,
        i.i_category,
        d_sold.d_year,
        ca.ca_state,
        cd.cd_gender,
        r_web.r_reason_desc
),
combined AS (
    SELECT
        channel_type,
        channel_key,
        sold_date_sk,
        sold_date,
        item_sk,
        item_id,
        brand,
        category,
        net_sales,
        return_amount,
        year,
        state,
        gender,
        reason_desc
    FROM store_agg
    UNION ALL
    SELECT
        channel_type,
        channel_key,
        sold_date_sk,
        sold_date,
        item_sk,
        item_id,
        brand,
        category,
        net_sales,
        return_amount,
        year,
        state,
        gender,
        reason_desc
    FROM web_agg
)
SELECT
    channel_type,
    channel_key,
    sold_date,
    item_id,
    brand,
    category,
    net_sales,
    return_amount,
    (net_sales - return_amount) AS net_profit,
    SUM(net_sales - return_amount) OVER (PARTITION BY channel_key ORDER BY sold_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_net_profit
FROM combined
ORDER BY channel_type, channel_key, sold_date
LIMIT 100
