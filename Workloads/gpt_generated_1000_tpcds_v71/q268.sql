WITH
    store_data AS (
        SELECT
            s.s_store_name,
            ds_sold.d_year,
            SUM(ss.ss_net_profit) AS store_sales_profit,
            SUM(COALESCE(-sr.sr_net_loss, 0)) AS store_returns_loss,
            SUM(ss.ss_ext_sales_price) AS store_sales_amount
        FROM store_sales ss
        JOIN date_dim ds_sold
          ON ss.ss_sold_date_sk = ds_sold.d_date_sk
        JOIN store s
          ON ss.ss_store_sk = s.s_store_sk
        JOIN customer_demographics cd
          ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
          ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca
          ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN income_band ib
          ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN store_returns sr
          ON sr.sr_ticket_number = ss.ss_ticket_number
         AND sr.sr_store_sk = s.s_store_sk
         AND sr.sr_cdemo_sk = cd.cd_demo_sk
         AND sr.sr_hdemo_sk = hd.hd_demo_sk
         AND sr.sr_addr_sk = ca.ca_address_sk
        LEFT JOIN date_dim ds_ret
          ON sr.sr_returned_date_sk = ds_ret.d_date_sk
        LEFT JOIN inventory inv
          ON ss.ss_sold_date_sk = inv.inv_date_sk
        WHERE ds_sold.d_year = 2002
        GROUP BY s.s_store_name, ds_sold.d_year
    ),
    web_data AS (
        SELECT
            ws.ws_order_number,
            ds_ws.d_year,
            SUM(ws.ws_net_profit) AS web_sales_profit,
            SUM(COALESCE(-wr.wr_net_loss, 0)) AS web_returns_loss,
            SUM(ws.ws_ext_sales_price) AS web_sales_amount,
            cd_bill.cd_gender,
            hd_bill.hd_buy_potential,
            ca_bill.ca_state
        FROM web_sales ws
        JOIN date_dim ds_ws
          ON ws.ws_sold_date_sk = ds_ws.d_date_sk
        JOIN customer_demographics cd_bill
          ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
        JOIN household_demographics hd_bill
          ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
        JOIN customer_address ca_bill
          ON ws.ws_bill_addr_sk = ca_bill.ca_address_sk
        JOIN customer_demographics cd_ship
          ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
        JOIN household_demographics hd_ship
          ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
        JOIN customer_address ca_ship
          ON ws.ws_ship_addr_sk = ca_ship.ca_address_sk
        LEFT JOIN web_returns wr
          ON wr.wr_order_number = ws.ws_order_number
        LEFT JOIN date_dim ds_wr
          ON wr.wr_returned_date_sk = ds_wr.d_date_sk
        WHERE ds_ws.d_year = 2002
        GROUP BY ws.ws_order_number, ds_ws.d_year, cd_bill.cd_gender, hd_bill.hd_buy_potential, ca_bill.ca_state
    )
SELECT
    sd.s_store_name,
    sd.d_year,
    sd.store_sales_profit,
    sd.store_returns_loss,
    sd.store_sales_amount,
    wd.web_sales_profit,
    wd.web_returns_loss,
    wd.web_sales_amount,
    ROW_NUMBER() OVER (PARTITION BY sd.d_year ORDER BY sd.store_sales_profit DESC) AS store_profit_rank
FROM store_data sd
LEFT JOIN web_data wd
  ON wd.d_year = sd.d_year
ORDER BY sd.store_sales_profit DESC
LIMIT 100
