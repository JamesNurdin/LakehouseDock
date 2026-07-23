WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS total_cs_sales,
        SUM(cs.cs_net_profit) AS total_cs_profit,
        COUNT(DISTINCT cs.cs_order_number) AS cs_order_cnt,
        SUM(ws.ws_ext_sales_price) AS total_ws_sales,
        SUM(ws.ws_net_profit) AS total_ws_profit,
        COUNT(DISTINCT ws.ws_order_number) AS ws_order_cnt,
        SUM(cr.cr_return_amount) AS total_cr_return_amount,
        SUM(wr.wr_return_amt) AS total_wr_return_amt,
        SUM(inv.inv_quantity_on_hand) AS total_inventory
    FROM
        date_dim d
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        LEFT JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
        LEFT JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
        LEFT JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
        LEFT JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
        LEFT JOIN customer_address ca ON ca.ca_address_sk = c.c_current_addr_sk
        LEFT JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
        LEFT JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
        LEFT JOIN reason r ON r.r_reason_sk = cr.cr_reason_sk
    WHERE
        d.d_year = 2001
        AND d.d_month_seq BETWEEN 1200 AND 1220
        AND ca.ca_state IN ('CA', 'TX', 'NY')
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '5000-10000'
        AND p.p_discount_active = 'Y'
    GROUP BY
        d.d_year,
        d.d_month_seq,
        c.c_customer_id,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        p.p_promo_name
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.c_customer_id,
    s.ca_state,
    s.cd_gender,
    s.hd_buy_potential,
    s.p_promo_name,
    s.total_cs_sales,
    s.total_ws_sales,
    s.total_cs_profit,
    s.total_ws_profit,
    s.cs_order_cnt,
    s.ws_order_cnt,
    s.total_cr_return_amount,
    s.total_wr_return_amt,
    s.total_inventory,
    CASE
        WHEN s.total_cs_profit > 100000 THEN 'HIGH'
        WHEN s.total_cs_profit > 50000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS cs_profit_category,
    RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY s.total_cs_sales DESC) AS cs_sales_rank
FROM
    sales_agg s
WHERE
    s.total_cs_sales > (
        SELECT AVG(total_cs_sales) FROM sales_agg
    )
ORDER BY
    s.d_year,
    s.d_month_seq,
    cs_sales_rank
LIMIT 100
