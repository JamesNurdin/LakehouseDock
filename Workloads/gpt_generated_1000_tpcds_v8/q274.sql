WITH intersected_customers AS (
    SELECT cs.cs_bill_customer_sk AS customer_sk
    FROM catalog_sales cs
    INTERSECT
    SELECT ws.ws_bill_customer_sk
    FROM web_sales ws
),
base_join AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_paid,
        cs.cs_order_number,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ws.ws_ext_sales_price,
        ws.ws_net_paid,
        c.c_customer_sk,
        c.c_birth_year,
        ib.ib_lower_bound,
        p.p_discount_active,
        i.i_item_sk,
        sm.sm_ship_mode_id,
        wr.wr_net_loss,
        sr.sr_store_credit,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    INNER JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    INNER JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    INNER JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    INNER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    INNER JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    INNER JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    INNER JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    INNER JOIN store_sales ss
        ON ss.ss_item_sk = i.i_item_sk
        AND ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_hdemo_sk = hd.hd_demo_sk
        AND ss.ss_addr_sk = ca.ca_address_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_customer_sk = c.c_customer_sk
        AND sr.sr_hdemo_sk = hd.hd_demo_sk
        AND sr.sr_addr_sk = ca.ca_address_sk
        AND sr.sr_ticket_number = ss.ss_ticket_number
    INNER JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    INNER JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    INNER JOIN web_returns wr
        ON wr.wr_item_sk = i.i_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_refunded_customer_sk = c.c_customer_sk
        AND wr.wr_returning_customer_sk = c.c_customer_sk
        AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_returning_hdemo_sk = hd.hd_demo_sk
        AND wr.wr_refunded_addr_sk = ca.ca_address_sk
        AND wr.wr_returning_addr_sk = ca.ca_address_sk
    WHERE
        ib.ib_lower_bound >= 40001
        AND cs.cs_sold_date_sk BETWEEN 2450590 AND 2450600
        AND ws.ws_quantity > 5
        AND c.c_customer_sk IN (SELECT customer_sk FROM intersected_customers)
        AND EXISTS (
            SELECT 1 FROM promotion p2
            WHERE p2.p_promo_sk = cs.cs_promo_sk
              AND p2.p_discount_active = 'Y'
        )
),
aggregated AS (
    SELECT
        c_customer_sk,
        c_birth_year,
        ib_lower_bound,
        SUM(cs_ext_sales_price + ss_ext_sales_price + ws_ext_sales_price) AS total_sales,
        SUM(cs_net_paid + ss_net_paid + ws_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        AVG(wr_net_loss) AS avg_wr_net_loss
    FROM base_join
    GROUP BY c_customer_sk, c_birth_year, ib_lower_bound
    HAVING SUM(cs_ext_sales_price) > 1000
)
SELECT
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS rn,
    c_customer_sk,
    c_birth_year,
    ib_lower_bound,
    total_sales,
    total_net_paid,
    orders_cnt,
    avg_wr_net_loss
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
