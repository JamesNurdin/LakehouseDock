WITH wh_inventory AS (
    SELECT
        inv.inv_date_sk,
        inv.inv_item_sk,
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        w.w_warehouse_sk,
        w.w_warehouse_name,
        w.w_city,
        w.w_state
    FROM inventory inv
    FULL OUTER JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
),
base AS (
    SELECT
        d_cs.d_year,
        cc.cc_name,
        whinv.w_warehouse_name,
        hd.hd_buy_potential,
        ca.ca_address_sk,
        cs.cs_net_paid,
        ss.ss_net_paid,
        ws.ws_net_paid,
        sr.sr_net_loss,
        whinv.inv_quantity_on_hand,
        d_cs.d_date
    FROM call_center cc
    JOIN catalog_sales cs
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN date_dim d_cs
        ON cs.cs_sold_date_sk = d_cs.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN wh_inventory whinv
        ON cs.cs_warehouse_sk = whinv.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_item_sk = ss.ss_item_sk
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
       AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
       AND ws.ws_warehouse_sk = whinv.w_warehouse_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    JOIN date_dim d_ws
        ON ws.ws_sold_date_sk = d_ws.d_date_sk
    JOIN date_dim d_inv
        ON whinv.inv_date_sk = d_inv.d_date_sk
    WHERE d_cs.d_year = 1998
      AND cc.cc_state = 'CA'
      AND hd.hd_buy_potential = '5001-10000'
      AND whinv.inv_quantity_on_hand > 200
      AND ws.ws_net_paid_inc_ship > 2000.00
      AND wp.wp_type = 'Content'
      AND d_cs.d_date BETWEEN DATE '1998-01-01' AND DATE '1998-12-31'
      AND EXISTS (
          SELECT 1 FROM income_band ib
          WHERE ib.ib_income_band_sk = hd.hd_income_band_sk
            AND ib.ib_lower_bound >= 50000
      )
      AND EXISTS (
          SELECT 1 FROM reason r
          WHERE r.r_reason_sk = sr.sr_reason_sk
            AND r.r_reason_id = 'R1'
      )
)
SELECT
    d_year,
    cc_name,
    w_warehouse_name,
    hd_buy_potential,
    COUNT(DISTINCT ca_address_sk) AS distinct_customers,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(sr_net_loss) AS total_return_loss,
    AVG(inv_quantity_on_hand) AS avg_inventory_quantity,
    MIN(d_date) AS earliest_sale_date
FROM base
GROUP BY d_year, cc_name, w_warehouse_name, hd_buy_potential
ORDER BY total_catalog_sales DESC
LIMIT 100
