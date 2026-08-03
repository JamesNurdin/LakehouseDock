WITH joined_data AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid_inc_tax,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        ss.ss_ext_list_price,
        ss.ss_coupon_amt,
        sr.sr_return_quantity,
        sr.sr_net_loss AS store_net_loss,
        c.c_customer_sk,
        c.c_birth_country,
        p.p_promo_id,
        r.r_reason_desc,
        s.s_store_name,
        wp.wp_url
    FROM catalog_sales cs
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE cs.cs_ext_ship_cost > 500
      AND ss.ss_ext_list_price < 10000
      AND cr.cr_net_loss > 0
),
union_set AS (
    SELECT c_customer_sk, c_birth_country, cs_ext_ship_cost, cs_net_paid_inc_tax, cr_net_loss
    FROM joined_data
    WHERE cs_ext_ship_cost > 800
    UNION
    SELECT c_customer_sk, c_birth_country, cs_ext_ship_cost, cs_net_paid_inc_tax, cr_net_loss
    FROM joined_data
    WHERE cr_net_loss > 50
)
SELECT
    ud.c_customer_sk,
    ud.c_birth_country,
    COUNT(*) AS txn_cnt,
    SUM(ud.cs_ext_ship_cost) AS total_ship_cost,
    AVG(ud.cs_net_paid_inc_tax) AS avg_net_paid_inc_tax,
    MAX(ud.cr_net_loss) AS max_return_loss
FROM union_set ud
WHERE ud.c_customer_sk IN (
      SELECT cr_returning_customer_sk FROM catalog_returns WHERE cr_net_loss > 100
      INTERSECT
      SELECT sr_customer_sk FROM store_returns WHERE sr_net_loss > 100
    )
  AND ud.cs_net_paid_inc_tax > (
        SELECT AVG(cs3.cs_net_paid_inc_tax)
        FROM catalog_sales cs3
        WHERE cs3.cs_quantity > 5
    )
GROUP BY ud.c_customer_sk, ud.c_birth_country
HAVING COUNT(*) > 1
ORDER BY total_ship_cost DESC
LIMIT 100
