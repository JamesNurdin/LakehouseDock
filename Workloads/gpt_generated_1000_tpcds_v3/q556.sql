WITH aggregated_sales AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        i.i_item_sk,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(cs.cs_net_profit) AS catalog_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_returns_loss,
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0)) AS total_net_profit,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_catalog_profit_per_item
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_return_time_sk = t.t_time_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d.d_date_sk
        AND cs.cs_sold_time_sk = t.t_time_sk
        AND cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
        AND wp.wp_creation_date_sk = d.d_date_sk
    WHERE
        d.d_year = 2001
        AND t.t_shift = 'first'
        AND hd.hd_buy_potential = '5001-10000'
    GROUP BY
        i.i_item_id,
        i.i_product_name,
        d.d_year,
        i.i_item_sk
    HAVING
        (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) + SUM(ws.ws_net_profit) - COALESCE(SUM(sr.sr_net_loss), 0)) > 10000
)
SELECT
    a.i_item_id,
    a.i_product_name,
    a.d_year,
    a.store_sales_profit,
    a.catalog_sales_profit,
    a.web_sales_profit,
    a.total_returns_loss,
    a.total_net_profit,
    a.avg_catalog_profit_per_item,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_net_profit DESC) AS profit_rank_year
FROM aggregated_sales a
ORDER BY profit_rank_year
LIMIT 100
