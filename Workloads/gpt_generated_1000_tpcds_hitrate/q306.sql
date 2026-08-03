WITH
    sales_agg AS (
        SELECT
            cs_item_sk,
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_bill_hdemo_sk,
            cs_call_center_sk,
            cs_ship_mode_sk,
            cs_sold_date_sk,
            cs_ship_date_sk,
            SUM(cs_net_paid) AS total_paid,
            COUNT(*) AS sales_cnt
        FROM catalog_sales
        WHERE cs_sold_date_sk BETWEEN 2450835 AND 2450906
        GROUP BY
            cs_item_sk,
            cs_bill_customer_sk,
            cs_bill_cdemo_sk,
            cs_bill_hdemo_sk,
            cs_call_center_sk,
            cs_ship_mode_sk,
            cs_sold_date_sk,
            cs_ship_date_sk
    ),
    returns_customers AS (
        SELECT DISTINCT cr_refunded_customer_sk AS c_customer_sk
        FROM catalog_returns
        WHERE cr_returned_date_sk BETWEEN 2450835 AND 2450906
    ),
    returns_agg AS (
        SELECT
            c.c_customer_id,
            d_ret.d_year,
            SUM(cr.cr_return_amount) AS total_return
        FROM catalog_returns cr
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
        GROUP BY c.c_customer_id, d_ret.d_year
    ),
    big_join AS (
        SELECT
            c.c_customer_id,
            d_sold.d_year,
            sa.total_paid,
            sa.sales_cnt,
            cc.cc_name,
            sm.sm_type,
            hd.hd_buy_potential,
            ib.ib_upper_bound,
            i.inv_quantity_on_hand,
            ws.ws_net_paid AS web_net_paid,
            ws.ws_order_number
        FROM sales_agg sa
        JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN date_dim d_sold ON sa.cs_sold_date_sk = d_sold.d_date_sk
        JOIN date_dim d_ship ON sa.cs_ship_date_sk = d_ship.d_date_sk
        JOIN customer c ON sa.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON sa.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON sa.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN inventory i TABLESAMPLE BERNOULLI (10)
            ON i.inv_date_sk = d_sold.d_date_sk
            AND i.inv_item_sk = sa.cs_item_sk
        JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_item_sk = sa.cs_item_sk
        JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        WHERE NOT EXISTS (
            SELECT 1 FROM returns_customers rc WHERE rc.c_customer_sk = c.c_customer_sk
        )
    )
SELECT DISTINCT
    bj.c_customer_id,
    bj.d_year,
    bj.total_paid,
    bj.sales_cnt
FROM big_join bj
EXCEPT
SELECT DISTINCT
    ra.c_customer_id,
    ra.d_year,
    ra.total_return,
    0 AS sales_cnt
FROM returns_agg ra
ORDER BY total_paid DESC
LIMIT 100
