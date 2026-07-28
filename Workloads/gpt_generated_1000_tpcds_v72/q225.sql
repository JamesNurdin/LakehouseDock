WITH base AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_item_sk,
        ws.ws_web_site_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_web_page_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_reason_sk,
        d_s.d_year,
        d_s.d_date,
        d_ret.d_month_seq,
        hd_bill.hd_buy_potential,
        hd_bill.hd_vehicle_count,
        hd_bill.hd_dep_count,
        ws_site.web_name,
        ws_site.web_company_id,
        r.r_reason_desc,
        cp.cp_department,
        cp.cp_catalog_page_number
    FROM web_sales ws
    JOIN date_dim d_s ON ws.ws_sold_date_sk = d_s.d_date_sk
    JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_bill ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN household_demographics hd_ship ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    LEFT JOIN web_returns wr ON ws.ws_item_sk = wr.wr_item_sk
        AND ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_s.d_date_sk
    LEFT JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_s.d_year = 2000
      AND hd_bill.hd_vehicle_count >= 1
      AND hd_bill.hd_buy_potential = '501-1000'
      AND ws_site.web_company_id IN (1, 2, 3)
      AND r.r_reason_desc LIKE '%customer%'
      AND cp.cp_department = 'electronics'
      AND d_ret.d_month_seq = 5
)
SELECT
    d_year,
    web_name,
    r_reason_desc,
    hd_buy_potential,
    SUM(ws_net_profit) AS total_profit,
    SUM(ws_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(SUM(ws_net_profit)) OVER (PARTITION BY d_year) AS profit_year_total,
    RANK() OVER (ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
FROM base
GROUP BY ROLLUP (d_year, web_name, r_reason_desc, hd_buy_potential)
HAVING SUM(ws_net_profit) > 1000
ORDER BY d_year NULLS LAST, total_profit DESC
LIMIT 100
