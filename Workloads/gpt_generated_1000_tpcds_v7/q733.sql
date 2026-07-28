WITH joined_data AS (
    SELECT
        d.d_date,
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        i.i_brand,
        ca.ca_country,
        p.p_discount_active,
        ss.ss_quantity,
        ss.ss_net_profit,
        inv.inv_quantity_on_hand,
        w.w_warehouse_name,
        wr.wr_return_quantity,
        ws.web_market_manager
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_returned_date_sk = d.d_date_sk
    JOIN inventory inv
        ON inv.inv_date_sk = d.d_date_sk
       AND inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_returned_time_sk = t.t_time_sk
       AND wr.wr_item_sk = i.i_item_sk
       AND wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
       AND wr.wr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND ca.ca_country = 'United States'
      AND p.p_discount_active = 'Y'
)
SELECT
    d_date,
    s_store_name,
    s_state,
    i_brand,
    SUM(ss_quantity) AS total_quantity,
    SUM(ss_net_profit) AS total_net_profit,
    SUM(inv_quantity_on_hand) AS total_on_hand,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY SUM(ss_net_profit) DESC) AS sales_rank,
    CASE 
        WHEN SUM(ss_net_profit) > 10000 THEN 'High'
        WHEN SUM(ss_net_profit) > 0 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category
FROM joined_data
GROUP BY d_date, s_store_name, s_state, i_brand
ORDER BY d_date, sales_rank
LIMIT 100
