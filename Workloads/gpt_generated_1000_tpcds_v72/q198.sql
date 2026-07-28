WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_promo_sk,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    GROUP BY
        ss_item_sk,
        ss_store_sk,
        ss_sold_date_sk,
        ss_sold_time_sk,
        ss_customer_sk,
        ss_cdemo_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        ss_promo_sk
)

SELECT DISTINCT
    d.d_year,
    i.i_item_id,
    i.i_product_name,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    ws.web_name,
    cc.cc_name,
    cp.cp_department,
    p.p_promo_name,
    CASE
        WHEN hd.hd_buy_potential = 'HIGH' THEN 'Premium'
        ELSE 'Standard'
    END AS customer_segment,
    total_net_profit,
    total_quantity,
    RANK() OVER (PARTITION BY d.d_year ORDER BY total_net_profit DESC) AS profit_rank,
    (SELECT COUNT(*)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_returned_date_sk = d.d_date_sk) AS returns_this_day
FROM ss_agg sa
JOIN date_dim d
    ON sa.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON sa.ss_sold_time_sk = t.t_time_sk
JOIN item i
    ON sa.ss_item_sk = i.i_item_sk
JOIN customer c
    ON sa.ss_customer_sk = c.c_customer_sk
JOIN customer_demographics cd
    ON sa.ss_cdemo_sk = cd.cd_demo_sk
JOIN household_demographics hd
    ON sa.ss_hdemo_sk = hd.hd_demo_sk
JOIN customer_address ca
    ON sa.ss_addr_sk = ca.ca_address_sk
JOIN promotion p
    ON sa.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
    ON sr.sr_item_sk = sa.ss_item_sk
   AND sr.sr_ticket_number = (
        SELECT MAX(ss_ticket_number)
        FROM store_sales
        WHERE ss_item_sk = sa.ss_item_sk
   )
JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
JOIN catalog_sales cs
    ON cs.cs_item_sk = i.i_item_sk
   AND cs.cs_sold_date_sk = d.d_date_sk
JOIN catalog_returns cr
    ON cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_wholesale_cost BETWEEN 0.5 AND 20
  AND c.c_birth_country = 'USA'
  AND p.p_discount_active = 'Y'
  AND ca.ca_state = 'CA'
  AND cc.cc_state = 'TX'
  AND ws.web_country = 'USA'
ORDER BY d.d_year, profit_rank, i.i_item_id
