WITH sales_agg AS (
    SELECT
        d.d_date,
        SUM(ss.ss_net_profit)          AS store_net_profit,
        SUM(cs.cs_net_profit)          AS catalog_net_profit,
        SUM(wr.wr_net_loss)            AS returns_net_loss
    FROM store_sales ss
    JOIN date_dim d                ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN call_center cc            ON cc.cc_open_date_sk = d.d_date_sk
    JOIN catalog_sales cs          ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp           ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm              ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p               ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd  ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca       ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN web_returns wr           ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r                  ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws               ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
      AND r.r_reason_desc LIKE '%color%'
      AND cp.cp_type = 'monthly'
    GROUP BY d.d_date
)
SELECT
    d_date,
    store_net_profit,
    catalog_net_profit,
    returns_net_loss,
    (store_net_profit + catalog_net_profit - returns_net_loss) AS total_net,
    RANK() OVER (ORDER BY (store_net_profit + catalog_net_profit - returns_net_loss) DESC) AS profit_rank
FROM sales_agg
ORDER BY total_net DESC
LIMIT 100
