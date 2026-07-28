WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        c.c_customer_id,
        c.c_customer_sk,
        i.i_category,
        i.i_brand,
        i.i_item_sk,
        i.i_current_price,
        cs.cs_net_profit   AS catalog_net_profit,
        ws.ws_net_profit   AS web_net_profit,
        cr.cr_net_loss     AS catalog_return_loss,
        wr.wr_net_loss     AS web_return_loss,
        cs.cs_quantity,
        CASE WHEN cs.cs_quantity > 10 THEN 'Bulk' ELSE 'Regular' END AS order_type,
        cc.cc_market_manager
    FROM date_dim d
    -- catalog sales and its dimensions
    JOIN catalog_sales cs          ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc           ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p              ON cs.cs_promo_sk = p.p_promo_sk
    -- web sales and its dimensions
    JOIN web_sales ws             ON ws.ws_sold_date_sk = d.d_date_sk
    -- catalog returns (joined only via date & item & customer)
    JOIN catalog_returns cr       ON cr.cr_returned_date_sk = d.d_date_sk
    -- web returns (joined via date & item & customer)
    JOIN web_returns wr           ON wr.wr_returned_date_sk = d.d_date_sk
    -- shared dimensions
    JOIN customer c               ON c.c_customer_sk = cs.cs_bill_customer_sk
                                 AND c.c_customer_sk = ws.ws_bill_customer_sk
                                 AND c.c_customer_sk = cr.cr_refunded_customer_sk
                                 AND c.c_customer_sk = wr.wr_refunded_customer_sk
    JOIN customer_address ca      ON ca.ca_address_sk = c.c_current_addr_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = c.c_current_cdemo_sk
    JOIN household_demographics hd ON hd.hd_demo_sk = c.c_current_hdemo_sk
    JOIN income_band ib           ON ib.ib_income_band_sk = hd.hd_income_band_sk
    JOIN item i                   ON i.i_item_sk = cs.cs_item_sk
                                 AND i.i_item_sk = ws.ws_item_sk
                                 AND i.i_item_sk = cr.cr_item_sk
                                 AND i.i_item_sk = wr.wr_item_sk
    -- store dimension (joined via its closed date, not via store_returns)
    JOIN store s                  ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2002
      AND i.i_current_price > 20
      AND cs.cs_net_profit > -1000
      AND ws.ws_net_profit > -1000
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND cc.cc_market_manager IS NOT NULL
),
agg_data AS (
    SELECT
        jd.d_year,
        jd.s_store_id,
        jd.s_store_name,
        SUM(jd.catalog_net_profit)   AS total_catalog_profit,
        SUM(jd.web_net_profit)       AS total_web_profit,
        SUM(jd.catalog_return_loss)  AS total_catalog_return_loss,
        SUM(jd.web_return_loss)      AS total_web_return_loss,
        COUNT(DISTINCT jd.c_customer_id) AS unique_customers,
        AVG(CASE WHEN jd.order_type = 'Bulk' THEN jd.catalog_net_profit END) AS avg_bulk_profit
    FROM joined_data jd
    WHERE EXISTS (
        SELECT 1
        FROM store_returns sr2
        WHERE sr2.sr_customer_sk = jd.c_customer_sk
          AND sr2.sr_net_loss > 500
    )
    GROUP BY jd.d_year, jd.s_store_id, jd.s_store_name
    HAVING SUM(jd.catalog_net_profit) > 10000
       AND SUM(jd.web_net_profit) > 5000
       AND COUNT(DISTINCT jd.c_customer_id) > 50
       AND SUM(jd.catalog_return_loss) < 2000
)
SELECT
    ad.*,
    ROW_NUMBER() OVER (PARTITION BY ad.d_year ORDER BY (ad.total_catalog_profit + ad.total_web_profit) DESC) AS rank_per_year
FROM agg_data ad
ORDER BY ad.d_year, rank_per_year
