WITH sub_a AS (
    SELECT
        d.d_year,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ws.w_warehouse_name,
        web.web_site_id,
        SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) AS sum_sales_price,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(cs.cs_net_paid, 0)) AS sum_net_profit,
        COUNT(DISTINCT COALESCE(ss.ss_ticket_number, cs.cs_order_number)) AS cnt_transactions,
        SUM(qty) AS total_quantity,
        CASE WHEN SUM(COALESCE(ss.ss_net_profit, 0)) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_category
    FROM
        store_sales ss
        JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        RIGHT JOIN warehouse ws ON cs.cs_warehouse_sk = ws.w_warehouse_sk
        LEFT JOIN web_site web ON web.web_open_date_sk = d.d_date_sk
        CROSS JOIN UNNEST(ARRAY[COALESCE(ss.ss_quantity, 0), COALESCE(cs.cs_quantity, 0)]) AS t(qty)
    WHERE
        d.d_year = 2002
        AND ca.ca_state IN ('CA', 'NY')
        AND cd.cd_gender = 'F'
        AND ib.ib_upper_bound > 50000
        AND ss.ss_quantity > 2
    GROUP BY CUBE (d.d_year, ca.ca_state, cd.cd_gender, hd.hd_buy_potential, ib.ib_income_band_sk, ws.w_warehouse_name, web.web_site_id)
    HAVING SUM(COALESCE(ss.ss_ext_sales_price, 0) + COALESCE(cs.cs_ext_sales_price, 0)) > 1000
),
sub_b AS (
    SELECT
        d_ret.d_year,
        ca.ca_state,
        cd.cd_gender,
        hd.hd_buy_potential,
        ib.ib_income_band_sk,
        ws.w_warehouse_name,
        web.web_site_id,
        SUM(COALESCE(cs.cs_ext_sales_price, 0)) AS sum_sales_price,
        SUM(COALESCE(wr.wr_net_loss, 0)) AS sum_net_profit,
        COUNT(DISTINCT COALESCE(cs.cs_order_number, wr.wr_order_number)) AS cnt_transactions,
        SUM(qty) AS total_quantity,
        CASE WHEN SUM(COALESCE(wr.wr_net_loss, 0)) > 0 THEN 'Positive' ELSE 'NonPositive' END AS profit_category
    FROM
        web_returns wr
        JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN catalog_sales cs ON cs.cs_sold_date_sk = d_ret.d_date_sk
        RIGHT JOIN warehouse ws ON cs.cs_warehouse_sk = ws.w_warehouse_sk
        JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN web_site web ON web.web_close_date_sk = d_ret.d_date_sk
        CROSS JOIN UNNEST(ARRAY[COALESCE(wr.wr_return_quantity, 0)]) AS t(qty)
    WHERE
        d_ret.d_year = 2002
        AND ca.ca_state = 'TX'
        AND cd.cd_gender = 'M'
        AND ib.ib_lower_bound >= 20000
        AND wr.wr_return_quantity > 1
    GROUP BY CUBE (d_ret.d_year, ca.ca_state, cd.cd_gender, hd.hd_buy_potential, ib.ib_income_band_sk, ws.w_warehouse_name, web.web_site_id)
    HAVING SUM(COALESCE(cs.cs_ext_sales_price, 0)) > 500
)
SELECT *
FROM (
    SELECT * FROM sub_a
    UNION
    SELECT * FROM sub_b
) AS combined
ORDER BY d_year DESC, sum_sales_price DESC
LIMIT 100
