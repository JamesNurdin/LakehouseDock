WITH base AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_store_sk,
        ss.ss_item_sk,
        ss.ss_ticket_number,
        ss.ss_net_profit AS ss_net_profit,
        ss.ss_quantity,
        cs.cs_sold_date_sk AS cs_sold_date_sk,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_catalog_page_sk,
        cs.cs_item_sk AS cs_item_sk,
        cs.cs_order_number,
        ws.ws_sold_date_sk AS ws_sold_date_sk,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_order_number,
        i.i_brand,
        i.i_current_price,
        hd.hd_income_band_sk,
        hd.hd_dep_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_month_seq,
        ca_bill.ca_address_sk AS bill_address_sk,
        ca_ship.ca_address_sk AS ship_address_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN catalog_sales cs ON ss.ss_item_sk = cs.cs_item_sk AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
    LEFT JOIN web_sales ws ON ss.ss_item_sk = ws.ws_item_sk AND ss.ss_sold_date_sk = ws.ws_sold_date_sk
    LEFT JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ib.ib_upper_bound > 50000
      AND i.i_current_price > 100
      AND hd.hd_dep_count >= 3
)
SELECT
    b.d_year,
    b.s_store_name,
    b.i_brand,
    b.hd_income_band_sk,
    b.ib_lower_bound,
    b.ib_upper_bound,
    b.ss_net_profit,
    b.cs_net_profit,
    b.ws_net_profit,
    COALESCE(sr.sr_net_loss, 0) AS store_return_loss,
    COALESCE(wr.wr_net_loss, 0) AS web_return_loss,
    cp.cp_department,
    r.r_reason_desc,
    ROW_NUMBER() OVER (PARTITION BY b.s_store_name ORDER BY b.ss_net_profit DESC) AS profit_rank
FROM base b
LEFT JOIN store_returns sr ON b.ss_ticket_number = sr.sr_ticket_number
LEFT JOIN web_returns wr ON b.ws_order_number = wr.wr_order_number
LEFT JOIN catalog_page cp ON b.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk OR wr.wr_reason_sk = r.r_reason_sk
WHERE EXISTS (
        SELECT 1 FROM reason r2 WHERE r2.r_reason_desc LIKE 'Customer%'
    )
  AND b.ib_lower_bound IS NOT NULL
  AND cp.cp_department IS NOT NULL
ORDER BY b.d_year DESC, profit_rank
LIMIT 100
