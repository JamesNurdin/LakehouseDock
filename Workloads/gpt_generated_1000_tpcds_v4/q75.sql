WITH base AS (
    SELECT
        i.i_brand AS i_brand,
        td.t_hour AS t_hour,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        COUNT(DISTINCT ws.ws_order_number) AS web_txns,
        AVG(i.i_current_price) AS avg_price,
        COUNT(*) FILTER (WHERE ws.ws_ship_mode_sk IS NOT NULL) AS shipped_orders
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd_store
        ON ss.ss_cdemo_sk = cd_store.cd_demo_sk
    JOIN customer_address ca_store
        ON ss.ss_addr_sk = ca_store.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill
        ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_address ca_bill
        ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
    WHERE i.i_rec_start_date >= DATE '2000-01-01'
      AND i.i_current_price > 20
      AND td.t_hour BETWEEN 8 AND 20
      AND ws_site.web_manager IN ('Richard Fuchs', 'Moses Hicks')
      AND w.w_gmt_offset > -5.00
    GROUP BY i.i_brand, td.t_hour
)
SELECT
    b.i_brand,
    b.t_hour,
    b.store_profit,
    b.web_profit,
    (b.store_profit + b.web_profit) AS total_profit,
    b.store_txns,
    b.web_txns,
    (SELECT COUNT(*) FROM item i2 WHERE i2.i_brand = b.i_brand) AS brand_item_count
FROM base b
WHERE b.store_profit > (SELECT AVG(store_profit) FROM base)
ORDER BY total_profit DESC
LIMIT 100
