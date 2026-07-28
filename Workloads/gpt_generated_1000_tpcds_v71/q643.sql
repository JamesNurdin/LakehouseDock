WITH recent_sales AS (
    SELECT DISTINCT
        cs.cs_sold_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit,
        cs.cs_quantity,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        d.d_year,
        d.d_date
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND cs.cs_quantity > 1
),
agg_sales AS (
    SELECT
        rs.cs_bill_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_id,
        ws.web_name,
        COUNT(DISTINCT rs.cs_order_number)               AS order_cnt,
        SUM(rs.cs_net_paid_inc_tax)                      AS total_paid,
        AVG(rs.cs_net_profit)                            AS avg_profit,
        SUM(CASE WHEN rs.cs_net_profit > 0 THEN rs.cs_net_profit ELSE 0 END) AS positive_profit,
        MAX(rs.cs_sold_date_sk)                          AS latest_sale_date_sk,
        CASE WHEN SUM(rs.cs_net_profit) > 0 THEN 'Overall Profit' ELSE 'Overall Loss' END AS overall_status
    FROM recent_sales rs
    JOIN customer c               ON rs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib            ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp          ON rs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p              ON rs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w              ON rs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i              ON i.inv_warehouse_sk = w.w_warehouse_sk AND i.inv_date_sk = rs.cs_sold_date_sk
    JOIN store_sales ss           ON ss.ss_customer_sk = c.c_customer_sk
    JOIN web_returns wr           ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_site ws              ON ws.web_open_date_sk = rs.cs_sold_date_sk
    WHERE hd.hd_buy_potential = '1001-5000'
      AND ib.ib_upper_bound <= 100000
      AND ca.ca_state = 'CA'
      AND cd.cd_purchase_estimate >= 5000
      AND EXISTS (
            SELECT 1
            FROM catalog_returns cr2
            WHERE cr2.cr_order_number = rs.cs_order_number
              AND cr2.cr_return_amount > 100
          )
    GROUP BY
        rs.cs_bill_customer_sk,
        c.c_customer_id,
        ca.ca_city,
        ca.ca_state,
        hd.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        p.p_promo_id,
        ws.web_name
)
SELECT
    a.c_customer_id,
    a.ca_city,
    a.ca_state,
    a.hd_buy_potential,
    a.ib_lower_bound,
    a.ib_upper_bound,
    a.order_cnt,
    a.total_paid,
    a.avg_profit,
    a.positive_profit,
    a.latest_sale_date_sk,
    a.overall_status,
    a.p_promo_id,
    a.web_name,
    ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.total_paid DESC) AS rank_by_paid
FROM agg_sales a
ORDER BY a.total_paid DESC
LIMIT 100
