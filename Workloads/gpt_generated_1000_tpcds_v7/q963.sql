WITH joined AS (
    SELECT 
        d.d_date,
        s.s_store_name,
        sr.sr_net_loss AS store_return_loss,
        cr.cr_net_loss AS catalog_return_loss,
        wr.wr_net_loss AS web_return_loss
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.inventory i
        ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN tpcds.store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.web_site we
        ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2002
      AND ss.ss_quantity > 5
      AND cr.cr_return_amount > 100.00
      AND i.inv_quantity_on_hand < 100
      AND we.web_name = 'Online Shop'
)
SELECT
    d_date,
    s_store_name,
    SUM(store_return_loss) AS total_store_return_loss,
    SUM(catalog_return_loss) AS total_catalog_return_loss,
    SUM(web_return_loss) AS total_web_return_loss,
    (SUM(store_return_loss) + SUM(catalog_return_loss) + SUM(web_return_loss)) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY (SUM(store_return_loss) + SUM(catalog_return_loss) + SUM(web_return_loss)) DESC) AS loss_rank
FROM joined
GROUP BY d_date, s_store_name
HAVING (SUM(store_return_loss) + SUM(catalog_return_loss) + SUM(web_return_loss)) > 0
ORDER BY d_date ASC, loss_rank ASC
LIMIT 100
