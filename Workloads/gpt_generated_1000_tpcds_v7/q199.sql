WITH base_agg AS (
    SELECT
        s.s_store_name AS store_name,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(sr.sr_net_loss) AS store_return_loss,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_returns_cnt
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_units = 'Each'
      AND ib.ib_upper_bound > 50000
    GROUP BY s.s_store_name, d.d_year
)
SELECT
    store_name,
    AVG(web_profit) AS avg_web_profit,
    AVG(store_return_loss) AS avg_store_return_loss,
    SUM(web_orders) AS total_web_orders,
    SUM(store_returns_cnt) AS total_store_returns
FROM base_agg
GROUP BY store_name
HAVING SUM(web_orders) > 1000
ORDER BY avg_web_profit DESC
LIMIT 100
