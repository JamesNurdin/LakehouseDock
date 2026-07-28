WITH sales_with_details AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_catalog_number,
        tp.t_hour,
        p.p_promo_name,
        p.p_discount_active,
        hd.hd_income_band_sk,
        ib.ib_upper_bound,
        c.c_first_name,
        c.c_last_name,
        ca.ca_city,
        ca.ca_state
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim tp
        ON cs.cs_sold_time_sk = tp.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cp.cp_department = 'Sports'
      AND tp.t_hour BETWEEN 8 AND 12
      AND p.p_discount_active = 'Y'
      AND ib.ib_upper_bound <= 120000
      AND cs.cs_quantity > 2
)
SELECT
    sd.cp_department,
    sd.cp_catalog_number,
    sd.c_first_name,
    sd.c_last_name,
    sd.ca_city,
    sd.ca_state,
    sd.cs_quantity,
    sd.cs_net_paid,
    sd.cs_net_profit,
    avg_dept.avg_net_profit,
    RANK() OVER (PARTITION BY sd.cp_department ORDER BY sd.cs_net_profit DESC) AS profit_rank,
    SUM(sd.cs_quantity) OVER (PARTITION BY sd.cs_bill_customer_sk ORDER BY sd.cs_sold_date_sk ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_quantity
FROM sales_with_details sd
JOIN (
    SELECT cp_department, AVG(cs_net_profit) AS avg_net_profit
    FROM sales_with_details
    GROUP BY cp_department
) avg_dept
    ON sd.cp_department = avg_dept.cp_department
WHERE sd.cs_net_profit > avg_dept.avg_net_profit * 0.5
ORDER BY sd.cp_department, profit_rank
LIMIT 100
