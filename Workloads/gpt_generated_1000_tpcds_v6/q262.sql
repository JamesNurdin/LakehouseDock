WITH base AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_channel_tv,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        w.w_warehouse_sk,
        w.w_state AS warehouse_state,
        inv.inv_quantity_on_hand,
        cs.cs_ext_sales_price AS catalog_sales_amount,
        ss.ss_ext_sales_price AS store_sales_amount,
        cs.cs_net_profit AS catalog_net_profit,
        ss.ss_net_profit AS store_net_profit,
        c.c_customer_sk,
        ca.ca_city,
        ws.web_tax_percentage,
        CASE
            WHEN (cs.cs_net_profit + ss.ss_net_profit) > 0 THEN 'Positive'
            ELSE 'Negative'
        END AS profit_flag
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk   = s.s_store_sk
    JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t            ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN promotion p           ON ss.ss_promo_sk   = p.p_promo_sk
    JOIN customer c            ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca   ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs      ON cs.cs_sold_date_sk = d.d_date_sk
                                 AND cs.cs_bill_customer_sk = c.c_customer_sk
                                 AND cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv         ON inv.inv_date_sk = d.d_date_sk
                                 AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr        ON wr.wr_returned_date_sk = d.d_date_sk
                                 AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN web_site ws           ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2001                       -- predicate 1
      AND s.s_state = 'CA'                                     -- predicate 2
      AND p.p_channel_tv = 'Y'                                 -- predicate 3
      AND ib.ib_lower_bound >= 30000                          -- predicate 4
      AND inv.inv_quantity_on_hand > 200                       -- predicate 5
      AND ws.web_tax_percentage > 0.05                        -- predicate 6
      AND NOT EXISTS (                                         -- anti‑join
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
        )
),
agg_store AS (
    SELECT
        s_store_sk,
        s_store_name,
        d_year,
        SUM(catalog_sales_amount + store_sales_amount) AS total_sales,
        SUM(catalog_net_profit + store_net_profit) AS total_profit,
        CASE WHEN SUM(catalog_net_profit + store_net_profit) > 0 THEN 'Positive' ELSE 'Negative' END AS profit_flag
    FROM base
    GROUP BY s_store_sk, s_store_name, d_year
),
avg_profit AS (
    SELECT AVG(total_profit) AS avg_profit FROM agg_store
)
SELECT
    a.d_year,
    a.s_store_name,
    a.profit_flag,
    a.total_sales,
    a.total_profit,
    RANK() OVER (PARTITION BY a.d_year ORDER BY a.total_profit DESC) AS profit_rank
FROM agg_store a
CROSS JOIN avg_profit ap
WHERE a.total_profit > ap.avg_profit               -- derived filter on aggregate
  AND a.total_sales > 100000                       -- additional filter
ORDER BY a.d_year, profit_rank
