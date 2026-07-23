WITH base_sales AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_store_sk,
        ss.ss_hdemo_sk,
        ss.ss_quantity,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        d.d_date,
        d.d_year,
        t.t_hour,
        i.i_product_name,
        i.i_brand,
        i.i_brand_id,
        i.i_category,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        s.s_store_name,
        s.s_state,
        s.s_country
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
)
SELECT
    bs.d_date,
    bs.d_year,
    bs.s_store_name,
    bs.s_state,
    bs.i_product_name,
    bs.i_brand,
    bs.i_category,
    CASE 
        WHEN bs.ss_net_profit > 0 THEN 'Profitable'
        ELSE 'Loss'
    END AS profit_status,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    r.r_reason_desc,
    inv.inv_quantity_on_hand,
    w.w_warehouse_name,
    ws.ws_quantity AS web_quantity,
    ws.ws_sales_price AS web_sales_price,
    ROW_NUMBER() OVER (PARTITION BY bs.s_store_name ORDER BY bs.ss_ext_sales_price DESC) AS store_sales_rank,
    (
        SELECT SUM(ss2.ss_ext_sales_price)
        FROM store_sales ss2
        WHERE ss2.ss_item_sk = bs.ss_item_sk
    ) AS total_item_sales
FROM base_sales bs
JOIN income_band ib ON bs.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN store_returns sr 
    ON bs.ss_ticket_number = sr.sr_ticket_number
   AND bs.ss_item_sk = sr.sr_item_sk
   AND sr.sr_store_sk = bs.ss_store_sk
   AND sr.sr_hdemo_sk = bs.hd_demo_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
LEFT JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
LEFT JOIN inventory inv 
    ON inv.inv_item_sk = bs.ss_item_sk
   AND inv.inv_date_sk = bs.ss_sold_date_sk
LEFT JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_sales ws 
    ON ws.ws_item_sk = bs.ss_item_sk
   AND ws.ws_sold_date_sk = bs.ss_sold_date_sk
   AND ws.ws_ship_date_sk = bs.ss_sold_date_sk
   AND ws.ws_bill_hdemo_sk = bs.hd_demo_sk
   AND ws.ws_ship_hdemo_sk = bs.hd_demo_sk
   AND ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE bs.d_year = 2002
  AND bs.i_brand_id IN (1, 2, 3)
  AND ib.ib_lower_bound >= 50000
  AND bs.s_state = 'CA'
ORDER BY bs.d_year DESC, bs.s_store_name, store_sales_rank
LIMIT 100
