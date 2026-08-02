WITH joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        cs.cs_sales_price,
        cs.cs_wholesale_cost,
        d.d_date,
        d.d_year,
        d.d_quarter_name,
        ca_bill.ca_state,
        cd_bill.cd_gender,
        hd_bill.hd_buy_potential,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        ss.ss_sales_price AS ss_sales_price,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        p.p_discount_active,
        inv.inv_quantity_on_hand,
        ws.web_name,
        wr.wr_return_amt_inc_tax,
        wr.wr_return_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN income_band ib ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
        AND ss.ss_cdemo_sk = cd_bill.cd_demo_sk
        AND ss.ss_hdemo_sk = hd_bill.hd_demo_sk
        AND ss.ss_addr_sk = ca_bill.ca_address_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d.d_date_sk
    LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_refunded_addr_sk = ca_bill.ca_address_sk
    WHERE d.d_year = 2000
        AND ca_bill.ca_state = 'CA'
        AND ib.ib_lower_bound >= 100000
        AND cs.cs_quantity > 5
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_name = p.p_promo_name
              AND p2.p_discount_active = 'Y'
        )
),
order_arrays AS (
    SELECT
        d.d_date,
        array_agg(j.cs_order_number) AS order_numbers,
        sum(j.cs_ext_sales_price) AS total_sales,
        count(*) AS sales_count
    FROM joined j
    JOIN date_dim d ON j.cs_sold_date_sk = d.d_date_sk
    GROUP BY d.d_date
),
non_returned_orders AS (
    SELECT cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 10
      AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
    EXCEPT
    SELECT wr_order_number
    FROM web_returns wr
    WHERE wr.wr_return_amt_inc_tax > 1000
      AND wr.wr_returned_date_sk IN (SELECT d_date_sk FROM date_dim WHERE d_year = 2000)
),
expanded_orders AS (
    SELECT
        oa.d_date,
        t.order_number,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_discount_amt,
        p.p_promo_name,
        p.p_discount_active
    FROM order_arrays oa
    CROSS JOIN UNNEST(oa.order_numbers) AS t(order_number)
    JOIN catalog_sales cs ON cs.cs_order_number = t.order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_order_number IN (SELECT cs_order_number FROM non_returned_orders)
)
SELECT
    eo.d_date,
    eo.order_number,
    eo.cs_sales_price,
    eo.cs_net_profit,
    eo.p_promo_name,
    eo.p_discount_active,
    (SELECT max(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_name = eo.p_promo_name) AS max_promo_cost,
    eo.cs_ext_discount_amt
FROM expanded_orders eo
WHERE eo.cs_ext_discount_amt > 0
ORDER BY eo.d_date DESC, eo.cs_sales_price DESC
LIMIT 100
