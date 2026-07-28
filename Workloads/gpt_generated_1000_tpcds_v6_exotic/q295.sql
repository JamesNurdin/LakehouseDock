-- goal: Identify top‑selling catalog and web sales combinations for the year 2001, enriched with promotion, call‑center and demographic information, and rank them by total sales.
WITH joined AS (
    SELECT
        d_sold.d_year,
        cc.cc_name,
        cp.cp_catalog_page_number,
        sm.sm_type,
        p.p_promo_name,
        c_bill.c_customer_id,
        cs.cs_quantity,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        wr.wr_return_amt,
        CASE WHEN cs.cs_net_profit > 1000000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        (
            SELECT MAX(ib2.ib_upper_bound)
            FROM income_band ib2
            WHERE ib2.ib_income_band_sk = hd_bill.hd_income_band_sk
        ) AS max_income_upper
    FROM catalog_sales cs
    JOIN date_dim d_sold               ON cs.cs_sold_date_sk   = d_sold.d_date_sk
    JOIN time_dim t_sold               ON cs.cs_sold_time_sk   = t_sold.t_time_sk
    JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
    JOIN promotion p                   ON cs.cs_promo_sk       = p.p_promo_sk
    JOIN customer c_bill               ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib                ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca_bill      ON cs.cs_bill_addr_sk   = ca_bill.ca_address_sk
    JOIN customer c_ship               ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship      ON cs.cs_ship_addr_sk   = ca_ship.ca_address_sk
    JOIN web_sales ws                 ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_returns wr               ON wr.wr_returned_date_sk = d_sold.d_date_sk
                                     AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r                     ON wr.wr_reason_sk = r.r_reason_sk
    WHERE d_sold.d_year = 2001
      AND cc.cc_gmt_offset BETWEEN -5 AND 5
      AND ib.ib_upper_bound > 100000
      AND p.p_discount_active = 'Y'
      AND cs.cs_quantity >= 5
      AND ws.ws_quantity >= 2
)
SELECT
    d_year,
    cc_name,
    cp_catalog_page_number,
    sm_type,
    p_promo_name,
    c_customer_id,
    total_sales,
    total_ws_sales,
    total_returns,
    profit_category,
    max_income_upper,
    SUM(total_sales) OVER (
        PARTITION BY d_year
        ORDER BY total_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_sales,
    ROW_NUMBER() OVER (
        PARTITION BY d_year
        ORDER BY total_sales DESC
    ) AS sales_rank
FROM (
    SELECT
        d_year,
        cc_name,
        cp_catalog_page_number,
        sm_type,
        p_promo_name,
        c_customer_id,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(ws_ext_sales_price) AS total_ws_sales,
        SUM(wr_return_amt)      AS total_returns,
        MAX(profit_category)    AS profit_category,
        MAX(max_income_upper)   AS max_income_upper
    FROM joined
    GROUP BY
        d_year,
        cc_name,
        cp_catalog_page_number,
        sm_type,
        p_promo_name,
        c_customer_id
) agg
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
